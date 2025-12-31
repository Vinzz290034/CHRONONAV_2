// chrono_application_backend/services/NavigationGraph.js

const fs = require('fs');
const path = require('path');

// --- Dependencies ---
const turf = require('@turf/turf'); 
const Graph = require('js-astar').Graph; 
// --------------------

// --- MOCK DATA (Using simple integers for reliable testing) ---
const MOCK_CORRIDORS = {
    "type": "FeatureCollection",
    "features": [
        {
            "type": "Feature",
            "properties": { "id": 1, "name": "Test Corridor" },
            "geometry": {
                "type": "LineString",
                "coordinates": [ [10, 10], [10.1, 10.1], [10.2, 10.2] ] // Lng, Lat
            }
        }
    ]
};
const MOCK_POIS = {
    "type": "FeatureCollection",
    "features": [
        {
            "type": "Feature",
            "properties": { "name": "Entrance", "id": "R001" },
            "geometry": {
                "type": "Point",
                "coordinates": [ 10, 10 ] // Lng, Lat (Matches start of corridor)
            }
        }
    ]
};
const EMPTY_LINKS = { "type": "FeatureCollection", "features": [] };


class NavigationGraph {
    constructor() {
        this.graphData = {}; 
        this.nodes = new Map(); 
        this.pois = {};         
    }

    /**
     * Uses MOCK data to load the graph structure.
     */
    async loadFromFiles() {
        console.log("Starting to load navigation graph using A* library...");
        
        const corridorsData = MOCK_CORRIDORS;
        const linksData = EMPTY_LINKS;
        const poiData = MOCK_POIS;

        this.graphData = this._buildGraph(corridorsData, linksData);
        this.pois = this._extractPOIs(poiData);

        console.log(`✅ Graph loaded with ${this.nodes.size} nodes.`);
        console.log(`Mapped ${Object.keys(this.pois).length} POIs to the graph.`);
        return this;
    }

    /**
     * Converts GeoJSON into a structured adjacency list for A*.
     */
    _buildGraph(corridorsData, linksData) {
        let nodeIdCounter = 0;
        const graphData = {}; 
        
        const getOrCreateNodeId = (coords) => {
            const key = `${coords[0].toFixed(6)},${coords[1].toFixed(6)}`;
            if (!this.nodes.has(key)) {
                const newNodeId = nodeIdCounter++;
                this.nodes.set(key, { id: newNodeId, coords: coords });
                graphData[newNodeId] = {};
                return newNodeId;
            }
            return this.nodes.get(key).id;
        };

        [corridorsData, linksData].forEach(geoJsonData => {
            geoJsonData.features.forEach(feature => {
                if (feature.geometry.type === 'LineString') {
                    const coordinates = feature.geometry.coordinates;
                    
                    for (let i = 0; i < coordinates.length - 1; i++) {
                        const startCoords = coordinates[i];
                        const endCoords = coordinates[i+1];

                        const startId = getOrCreateNodeId(startCoords);
                        const endId = getOrCreateNodeId(endCoords);
                        
                        const segmentDistance = turf.distance(
                            turf.point(startCoords), 
                            turf.point(endCoords), 
                            { units: 'meters' }
                        );

                        // Add edge in both directions
                        graphData[startId][endId] = segmentDistance;
                        graphData[endId][startId] = segmentDistance;
                    }
                }
            });
        });
        
        return graphData;
    }
    
    /**
     * Extracts POIs and maps them to the nearest graph node.
     */
    _extractPOIs(poiData) {
        const poisMap = {};
        
        poiData.features.forEach(feature => {
            // 1. Prioritize ID, then Name
            const rawPoiId = feature.properties.id || feature.properties.name; 

            // 2. CRITICAL FIX: Ensure the stored key is always lowercase for consistency
            const poiId = String(rawPoiId).toLowerCase();
            
            if (poiId && feature.geometry.type === 'Point') {
                const [lng, lat] = feature.geometry.coordinates;
                const poiCoords = [lng, lat];
                
                let nearestNodeId = null;
                let minDistance = Infinity;

                for (const [key, node] of this.nodes) {
                    const distance = turf.distance(
                        turf.point(poiCoords),
                        turf.point(node.coords),
                        { units: 'meters' }
                    );

                    if (distance < minDistance) {
                        minDistance = distance;
                        nearestNodeId = node.id;
                    }
                }

                if (nearestNodeId !== null) {
                     poisMap[poiId] = nearestNodeId; 
                }
            }
        });
        
        // This log line is critical for debugging the key type/value
        console.log("DEBUG: Final POIs Map:", poisMap);
        
        return poisMap;
    }


    /**
     * Finds the closest graph node to the user's real-time coordinates.
     */
    findNearestNode(coords, floorID) {
        const userPoint = turf.point([coords.lng, coords.lat]);
        let nearestNodeId = null;
        let minDistance = Infinity;
        const MAX_DISTANCE_M = 5; 

        for (const [key, node] of this.nodes) {
            const distance = turf.distance(
                userPoint, 
                turf.point(node.coords), 
                { units: 'meters' }
            );

            if (distance < minDistance) {
                minDistance = distance;
                nearestNodeId = node.id;
            }
        }
        
        // Temporary debug logic: Always returns the nearest node (no distance limit)
        console.log(`Found nearest node ${nearestNodeId} at distance ${minDistance.toFixed(3)}m.`); 
        return nearestNodeId;
    }

    getPOI_NodeId(destinationPOI_ID, floorID) {
        // CRITICAL FIX: Ensure the lookup key is always lowercase
        const key = String(destinationPOI_ID).toLowerCase();
        return this.pois[key];
    }

    calculateShortestPath(startNodeId, endNodeId) {
        if (!this.graphData || this.nodes.size === 0 || startNodeId === null || endNodeId === null) {
            return { coordinates: [], distance: 0, error: "Graph not ready or nodes not found." };
        }
        
        const graph = new Graph(this.graphData);
        
        const heuristic = (a, b) => {
            const nodeA = Array.from(this.nodes.values()).find(n => n.id === parseInt(a));
            const nodeB = Array.from(this.nodes.values()).find(n => n.id === parseInt(b));
            
            if (!nodeA || !nodeB) return Infinity;

            return turf.distance(
                turf.point(nodeA.coords), 
                turf.point(nodeB.coords), 
                { units: 'meters' }
            );
        };

        const path = graph.findShortestPath(String(startNodeId), String(endNodeId), {
            heuristic: heuristic,
            closest: true 
        });

        if (!path || path.length === 0) {
            return { coordinates: [], distance: 0, error: "No path exists between nodes." };
        }

        let totalDistance = 0;
        const pathCoordinates = [];

        for (let i = 0; i < path.length; i++) {
            const nodeId = parseInt(path[i]);
            const node = Array.from(this.nodes.values()).find(n => n.id === nodeId);
            
            if (node) {
                 pathCoordinates.push({ 
                     lat: node.coords[1], 
                     lng: node.coords[0]  
                 });
                 
                 if (i > 0) {
                     const prevNodeId = parseInt(path[i-1]);
                     const segmentDistance = this.graphData[prevNodeId][nodeId];
                     if (segmentDistance) {
                         totalDistance += segmentDistance;
                     }
                 }
            }
        }

        return { 
            coordinates: pathCoordinates, 
            distance: totalDistance 
        };
    }
}

// Export a single instance of the class
module.exports = new NavigationGraph();