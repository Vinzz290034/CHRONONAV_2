// chrono_application_backend/routes/navigationRoutes.js

const express = require('express');
const router = express.Router();

// The entire module is now exported as a function that must be called 
// with the loaded NavigationGraph instance from server.js.
module.exports = (navGraph) => { 

    if (!navGraph || navGraph.nodes.size === 0) {
        console.error("CRITICAL: NavigationGraph instance is missing or empty. Cannot define routes.");
        // Define a fallback route that returns a 503 error if the graph failed to load.
        router.post('/route', (req, res) => {
            return res.status(503).json({ error: "Navigation service is unavailable. Map data failed to load." });
        });
        return router;
    }

    /**
     * @route POST /api/v1/route
     * @desc Calculates the shortest path between a starting point and a destination POI.
     */
    router.post('/route', async (req, res) => {
        // 1. Get request parameters from the Flutter app
        const { startCoords, destinationPOI_ID, floorID } = req.body; 

        // 2. Basic input validation
        if (!startCoords || typeof startCoords.lat !== 'number' || typeof startCoords.lng !== 'number' || !destinationPOI_ID || !floorID) {
            console.error("Invalid input received:", req.body);
            return res.status(400).json({ 
                error: 'Missing or invalid route parameters. Required: startCoords (lat/lng), destinationPOI_ID, floorID.' 
            });
        }

        try {
            // --- Core Routing Logic ---

            // 3. Map Start Coords to Graph Node
            // The navGraph object is now guaranteed to be the fully loaded instance.
            const startNodeId = navGraph.findNearestNode(startCoords, floorID);
            
            if (startNodeId === null || startNodeId === undefined) {
                 // The findNearestNode method is returning null, triggering this error.
                 console.error("Routing failure: Start point failed to snap to a node.", startCoords);
                 return res.status(404).json({ error: 'Could not find a valid starting point on the map.' });
            }

            // 4. Get Destination Node
            const endNodeId = navGraph.getPOI_NodeId(destinationPOI_ID, floorID);
            
            if (!endNodeId) {
                return res.status(404).json({ error: `Destination POI '${destinationPOI_ID}' not found or not routable.` });
            }

            // 5. Calculate Path
            const pathResult = navGraph.calculateShortestPath(startNodeId, endNodeId);
            
            if (!pathResult || pathResult.coordinates.length === 0) {
                return res.status(404).json({ error: 'No path could be found between the start and destination.' });
            }

            // 6. Send Path to Mobile App
            res.json({ 
                success: true, 
                message: "Route calculated successfully.",
                path: pathResult.coordinates,
                distance_meters: pathResult.distance,
            });

        } catch (error) {
            console.error("Routing calculation failed:", error);
            res.status(500).json({ error: 'Internal server error during route calculation.' });
        }
    });

    return router;
};