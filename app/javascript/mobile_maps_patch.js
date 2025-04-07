
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              /**
 * Mobile Maps Patch
 * 
 * This script fixes Google Maps rendering issues on mobile devices.
 * Include this script in your application.js or add it as a separate import.
 */

document.addEventListener('DOMContentLoaded', function() {
  // Detect mobile devices
  const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
  
  if (isMobile) {
    console.log("Mobile device detected, applying maps patch");
    
    // Add viewport meta tag if it doesn't exist
    if (!document.querySelector('meta[name="viewport"]')) {
      const viewportMeta = document.createElement('meta');
      viewportMeta.name = 'viewport';
      viewportMeta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
      document.head.appendChild(viewportMeta);
    }
    
    // Add CSS styles for mobile map optimization
    const mobileMapStyles = `
      /* Mobile Maps CSS - Ensures proper rendering on mobile devices */
      @media (max-width: 768px) {
        .map-container {
          width: 100% !important;
          height: 300px !important;
          max-width: 100vw !important;
          position: relative !important;
          z-index: 1 !important;
          overflow: hidden !important;
        }
        
        .gm-style button {
          min-width: 32px !important;
          min-height: 32px !important;
        }
        
        .gm-style .gm-style-iw-c {
          padding: 12px !important;
          font-size: 16px !important;
        }
        
        .custom-map-control {
          margin: 8px !important;
        }
        
        .map-control-button {
          padding: 10px !important;
        }
        
        .gm-style svg {
          width: auto !important;
          height: auto !important;
        }
        
        .gm-style {
          font-size: 16px !important;
        }
      }

      .map-container {
        touch-action: pan-x pan-y !important;
      }

      .gm-style img {
        max-width: none !important;
      }

      .mobile-marker {
        width: 30px !important;
        height: 30px !important;
        border-radius: 50% !important;
        border: 2px solid white !important;
        box-shadow: 0 2px 4px rgba(0,0,0,0.3) !important;
      }

      .map-container:empty::before {
        content: "Loading map...";
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100%;
        font-style: italic;
        color: #666;
        background-color: #f8f8f8;
      }
    `;
    
    // Inject the CSS
    const styleElement = document.createElement('style');
    styleElement.textContent = mobileMapStyles;
    document.head.appendChild(styleElement);
    
    // Fix any map containers
    document.querySelectorAll('.map-container').forEach(container => {
      container.style.width = '100%';
      container.style.height = '300px'; // Default height for maps on mobile
      container.style.maxWidth = '100vw';
      container.style.position = 'relative';
      container.style.zIndex = '1'; // Ensure map appears above other elements
      
      // Add data attribute to mark as mobile-optimized
      container.dataset.mobileOptimized = 'true';
    });
    
    // Patch for Stimulus controllers
    document.addEventListener('stimulus:connect', function(event) {
      const controller = event.detail.controller;
      
      // Only patch map controllers
      if (controller.identifier === 'map') {
        console.log("Patching map controller for mobile");
        
        // Ensure the map container has proper dimensions
        if (controller.hasMapContainerTarget) {
          controller.mapContainerTarget.style.width = '100%';
          controller.mapContainerTarget.style.height = '300px';
          controller.mapContainerTarget.style.maxWidth = '100vw';
          controller.mapContainerTarget.style.position = 'relative';
        }
        
        // Monkey patch the initializeMap method if it exists
        if (controller.initializeMap) {
          const originalInitializeMap = controller.initializeMap;
          
          controller.initializeMap = async function() {
            try {
              // Run the original method
              await originalInitializeMap.call(this);
              
              // Apply mobile-specific settings to the map if it exists
              if (this.map) {
                // Set mobile-friendly options
                this.map.setOptions({
                  gestureHandling: 'cooperative', // Better touch handling
                  zoomControl: true,
                  streetViewControl: false,
                  mapTypeControl: false,
                  fullscreenControl: false,
                });
                
                console.log("Applied mobile optimizations to map");
              }
            } catch (error) {
              console.error("Error in mobile map patch:", error);
            }
          };
        }
        
        // Monkey patch the createMarker method to use standard markers on mobile
        if (controller.createMarker) {
          const originalCreateMarker = controller.createMarker;
          
          controller.createMarker = function(position, label, type) {
            // If google.maps.marker.AdvancedMarkerElement isn't available or we're on mobile,
            // create a standard marker instead
            if (!window.google || !window.google.maps || 
                !window.google.maps.marker || !window.google.maps.marker.AdvancedMarkerElement) {
              
              let markerColor = "#367CFF"; // Default blue
              if (type === "origin-marker") {
                markerColor = "#4CAF50"; // Green for pickup
              } else if (type === "destination-marker") {
                markerColor = "#F44336"; // Red for dropoff
              }
              
              // Create standard marker
              const marker = new google.maps.Marker({
                position: position,
                map: this.map,
                label: {
                  text: label,
                  color: "#FFFFFF",
                  fontWeight: "bold"
                },
                icon: {
                  path: google.maps.SymbolPath.CIRCLE,
                  fillColor: markerColor,
                  fillOpacity: 1,
                  strokeWeight: 2,
                  strokeColor: "#FFFFFF",
                  scale: 10
                },
                title: type === "origin-marker" ? "Pickup Location" :
                       type === "destination-marker" ? "Dropoff Location" : "Location"
              });
              
              marker.type = type;
              
              // Add to markers array if it exists
              if (this.currentMarkers) {
                this.currentMarkers.push(marker);
              }
              
              return marker;
            } else {
              // Use the original method if AdvancedMarkerElement is available
              return originalCreateMarker.call(this, position, label, type);
            }
          };
        }
      }
    });
  }
});
