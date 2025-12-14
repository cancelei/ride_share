// Warehouse Interest Form Handler

document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('warehouseForm');
    
    if (form) {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            
            // Get form data
            const formData = {
                storageItems: document.getElementById('storage-items').value,
                spaceNeeded: document.getElementById('space-needed').value,
                timeline: document.getElementById('timeline').value,
                duration: document.getElementById('duration').value,
                name: document.getElementById('name').value,
                email: document.getElementById('email').value,
                phone: document.getElementById('phone').value,
                additionalInfo: document.getElementById('additional-info').value
            };
            
            // Create WhatsApp message
            const message = `🏭 *Warehouse Storage Interest*

*What to store:* ${formData.storageItems}
*Space needed:* ${formData.spaceNeeded}
*Timeline:* ${formData.timeline}
*Duration:* ${formData.duration || 'Not specified'}

*Contact Information:*
Name: ${formData.name}
Email: ${formData.email}
Phone: ${formData.phone || 'Not provided'}

*Additional Info:*
${formData.additionalInfo || 'None'}`;

            // Encode message for URL
            const encodedMessage = encodeURIComponent(message);
            
            // Replace with your WhatsApp number
            const whatsappNumber = '19707690951';
            const whatsappURL = `https://wa.me/${whatsappNumber}?text=${encodedMessage}`;
            
            // Open WhatsApp
            window.open(whatsappURL, '_blank');
            
            // Show success message
            alert('Thank you! Opening WhatsApp to send your request...');
            
            // Optional: Reset form
            form.reset();
        });
    }
});
