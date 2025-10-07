// ═══════════════════════════════════════════════════════════════════════════════════════
// F4-Crafting System - UI Script
// Author: F4 Development
// Description: Client-side UI logic for crafting interface
// ═══════════════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════════════════
// GLOBAL VARIABLES
// ═══════════════════════════════════════════════════════════════════════════════════════
let selectedItem = 0;
let playerLevel = 1;
let items = [];
let inventory = {};

// ═══════════════════════════════════════════════════════════════════════════════════════
// ITEM SELECTION & RENDERING
// ═══════════════════════════════════════════════════════════════════════════════════════
// Select an item from the list
function selectItem(index) {
    if (!items[index]) return;
    
    // Check if item is locked
    if (items[index].level > playerLevel) {
        return;
    }
    
    // Remove active class from all items
    document.querySelectorAll('.item-card').forEach(card => {
        card.classList.remove('active');
    });
    
    // Add active class to selected item
    document.querySelectorAll('.item-card')[index].classList.add('active');
    
    // Update main display
    const itemNameEl = document.querySelector('.item-name');
    const itemPreviewEl = document.querySelector('.item-preview');
    
    if (itemNameEl) itemNameEl.textContent = items[index].name;
    if (itemPreviewEl) {
        itemPreviewEl.src = items[index].image;
        itemPreviewEl.alt = items[index].name;
    }
    
    selectedItem = index;
    
    // Update inventory display for this item
    updateInventoryDisplay();
}

// Update item locks based on player level
function updateItemLocks() {
    const itemCards = document.querySelectorAll('.item-card');
    itemCards.forEach((card, index) => {
        if (items[index].level > playerLevel) {
            card.classList.add('locked');
            
            // Add lock icon if it doesn't exist
            if (!card.querySelector('.lock-icon')) {
                const lockIcon = document.createElement('div');
                lockIcon.className = 'lock-icon';
                lockIcon.innerHTML = '<svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V8a5 5 0 0 1 10 0v3"/></svg>';
                card.appendChild(lockIcon);
            }
            
            card.onclick = null;
        } else {
            card.classList.remove('locked');
            
            // Remove lock icon if exists
            const lockIcon = card.querySelector('.lock-icon');
            if (lockIcon) {
                lockIcon.remove();
            }
            
            // Restore onclick
            card.onclick = () => selectItem(index);
        }
    });
}

// Render items in sidebar
function renderItems() {
    const sidebar = document.querySelector('.sidebar .flex-1');
    if (!sidebar) return;
    
    sidebar.innerHTML = '';
    
    items.forEach((item, index) => {
        const itemCard = document.createElement('div');
        itemCard.className = 'item-card';
        if (index === 0) itemCard.classList.add('active');
        itemCard.onclick = () => selectItem(index);
        
        itemCard.innerHTML = `
            <div class="flex items-center mb-2">
                <img src="${item.image}" alt="${item.name}" class="w-8 h-8 mr-3">
                <div class="flex-1">
                    <div class="flex items-center justify-between">
                        <h3 class="text-white font-semibold text-sm">${item.name}</h3>
                        <span class="level-badge">Lvl ${item.level}</span>
                    </div>
                    <p class="text-xs secondary-text mt-1">${item.description}</p>
                </div>
            </div>
        `;
        
        sidebar.appendChild(itemCard);
    });
    
    updateItemLocks();
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// INVENTORY DISPLAY
// ═══════════════════════════════════════════════════════════════════════════════════════
// Update inventory display based on selected item
function updateInventoryDisplay() {
    if (items.length === 0 || !items[selectedItem]) return;
    
    const requirements = items[selectedItem].requirements || [];
    const resourcesContainer = document.querySelector('.resources-grid');
    if (!resourcesContainer) return;
    
    resourcesContainer.innerHTML = '';
    
    // Adjust grid density based on number of requirements
    resourcesContainer.classList.remove('dense', 'ultra');
    if (requirements.length >= 7 && requirements.length <= 9) {
        resourcesContainer.classList.add('dense');
    } else if (requirements.length >= 10) {
        resourcesContainer.classList.add('ultra');
    }
    
    requirements.forEach(req => {
        const hasAmount = inventory[req.item] || 0;
        const needAmount = req.amount;
        const hasEnough = hasAmount >= needAmount;
        
        const resourceSlot = document.createElement('div');
        resourceSlot.className = 'resource-slot';
        resourceSlot.innerHTML = `
            <img src="nui://ox_inventory/web/images/${req.item}.png" alt="${req.label}" class="w-12 h-12 mx-auto mb-3">
            <h3 class="text-white font-semibold text-sm mb-1">${req.label}</h3>
            <p class="text-xs secondary-text mb-2">REQUIRED: ${needAmount}</p>
            <p class="font-orbitron text-lg font-bold ${hasEnough ? 'text-green-400' : 'text-red-400'}">${hasAmount}</p>
        `;
        
        resourcesContainer.appendChild(resourceSlot);
    });
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// CRAFTING FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════════════
// Open crafting modal
function craftItem() {
    const quantity = parseInt(document.getElementById('quantity').value);
    const itemName = items[selectedItem].name;
    const itemImage = items[selectedItem].image;
    
    const modal = document.getElementById('craftModal');
    if (!modal) return;
    
    // Update modal content
    document.getElementById('modalItemImage').src = itemImage;
    document.getElementById('modalItemImage').alt = itemName;
    document.getElementById('modalItemName').textContent = itemName;
    document.getElementById('modalQuantityValue').textContent = quantity;
    
    // Show modal
    modal.style.display = 'flex';
    modal.style.visibility = 'visible';
    modal.style.opacity = '1';
    modal.classList.add('show');
}

// Confirm craft action
function confirmCraft() {
    const quantity = parseInt(document.getElementById('quantity').value);
    
    // Hide modal
    const modal = document.getElementById('craftModal');
    modal.style.display = 'none';
    modal.classList.remove('show');
    
    // Send to Lua
    fetch(`https://${GetParentResourceName()}/craft`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            itemIndex: selectedItem,
            quantity: quantity
        })
    }).then(resp => resp.json()).catch(err => {});
}

// Cancel craft action
function cancelCraft() {
    const modal = document.getElementById('craftModal');
    modal.style.display = 'none';
    modal.classList.remove('show');
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// QUANTITY CONTROLS
// ═══════════════════════════════════════════════════════════════════════════════════════
// Increase quantity
function increaseQuantity() {
    const input = document.getElementById('quantity');
    const currentValue = parseInt(input.value);
    const maxValue = parseInt(input.max);
    
    if (currentValue < maxValue) {
        input.value = currentValue + 1;
    }
}

// Decrease quantity
function decreaseQuantity() {
    const input = document.getElementById('quantity');
    const currentValue = parseInt(input.value);
    const minValue = parseInt(input.min);
    
    if (currentValue > minValue) {
        input.value = currentValue - 1;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// LEVEL DISPLAY
// ═══════════════════════════════════════════════════════════════════════════════════════
// Update level display with hexagons
function updateLevelDisplay(level, xp, xpRequired, xpPerHex = 100) {
    const levelStart = document.querySelector('.level-start');
    const levelEnd = document.querySelector('.level-end');
    
    if (levelStart) levelStart.textContent = level;
    if (levelEnd) levelEnd.textContent = level + 1;
    
    // Wrap hexagons in containers for labels
    const hexContainer = document.querySelector('.level-hexagons');
    const rawHexes = document.querySelectorAll('.level-hex');
    rawHexes.forEach(hex => {
        if (!hex.parentElement.classList.contains('hex-wrap')) {
            const wrap = document.createElement('div');
            wrap.className = 'hex-wrap';
            hexContainer.replaceChild(wrap, hex);
            wrap.appendChild(hex);
        }
    });

    const hexCells = document.querySelectorAll('.hex-wrap .level-hex');
    if (!hexCells || hexCells.length === 0) return;
    
    const part = xpPerHex;
    const completed = Math.floor(xp / part);
    const xpInPart = xp - (completed * part);
    const ratio = Math.max(0, Math.min(1, xpInPart / part));
    
    hexCells.forEach((cell, idx) => {
        cell.classList.remove('active', 'current', 'completed', 'locked');
        const iconHolder = cell.querySelector('.hex-icon');
        
        // Find or create XP label
        const wrap = cell.parentElement;
        let xpLabel = wrap.querySelector('.hex-xp-label');
        if (!xpLabel) {
            xpLabel = document.createElement('div');
            xpLabel.className = 'hex-xp-label';
            wrap.appendChild(xpLabel);
        }
        
        if (idx < completed) {
            // Completed hexagon
            cell.classList.add('completed');
            if (iconHolder) iconHolder.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>';
            xpLabel.textContent = '✓';
            xpLabel.style.color = '#10b981';
        } else if (idx === completed) {
            // Current hexagon
            cell.classList.add('current', 'active');
            cell.style.setProperty('--xp', ratio.toString());
            cell.title = `XP ${Math.round(xpInPart)}/${Math.round(part)}`;
            if (iconHolder) iconHolder.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/></svg>';
            const remaining = Math.ceil(part - xpInPart);
            xpLabel.textContent = remaining;
            xpLabel.style.color = '#3b82f6';
        } else {
            // Locked hexagon
            cell.classList.add('locked');
            if (iconHolder) iconHolder.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V8a5 5 0 0 1 10 0v3"/></svg>';
            xpLabel.textContent = Math.round(part);
            xpLabel.style.color = '#6b7280';
        }
    });
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// NOTIFICATION SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════════════
// Show notification in UI
function showNotification(message, type = 'info') {
    // Remove existing notifications
    const existingNotifications = document.querySelectorAll('.ui-notification');
    existingNotifications.forEach(notification => notification.remove());
    
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `ui-notification ui-notification-${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <div class="notification-icon">
                ${type === 'success' ? '✓' : type === 'error' ? '✕' : 'ℹ'}
            </div>
            <div class="notification-message">${message}</div>
        </div>
    `;
    
    // Add to UI
    const uiScale = document.querySelector('.ui-scale');
    if (uiScale) {
        uiScale.appendChild(notification);
        
        // Animate in
        setTimeout(() => {
            notification.classList.add('show');
        }, 10);
        
        // Auto remove after 5 seconds
        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.remove();
                }
            }, 300);
        }, 5000);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// UTILITY FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════════════════
// Get resource name
function GetParentResourceName() {
    let resourceName = 'F4-Crafting';
    if (window.location.href.includes('://nui-')) {
        resourceName = window.location.href.split('://nui-')[1].split('/')[0];
    }
    return resourceName;
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// EVENT LISTENERS
// ═══════════════════════════════════════════════════════════════════════════════════════
// Listen for NUI messages from Lua
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'open') {
        items = data.items || [];
        playerLevel = (data.playerLevel !== undefined && data.playerLevel !== null) ? data.playerLevel : 0;
        inventory = data.inventory || {};
        const xpRequired = data.xpRequired || 600;
        const xpPerHex = data.xpPerHex || 100;
        const playerXP = (data.playerXP !== undefined && data.playerXP !== null) ? data.playerXP : 0;
        
        // Update UI with data
        renderItems();
        updateInventoryDisplay();
        updateLevelDisplay(playerLevel, playerXP, xpRequired, xpPerHex);
        
        // Show UI
        const wrapper = document.querySelector('.ui-scale-wrapper');
        if (wrapper) wrapper.style.display = 'flex';
        
        // Select first available item
        selectItem(0);
    } else if (data.action === 'close') {
        const wrapper = document.querySelector('.ui-scale-wrapper');
        if (wrapper) wrapper.style.display = 'none';
    } else if (data.action === 'updateInventory') {
        inventory = data.inventory || {};
        updateInventoryDisplay();
    } else if (data.action === 'updateLevel') {
        const xpRequired = data.xpRequired || 600;
        const xpPerHex = data.xpPerHex || 100;
        updateLevelDisplay(data.level, data.xp, xpRequired, xpPerHex);
        playerLevel = data.level;
        updateItemLocks();
    } else if (data.action === 'showNotification') {
        showNotification(data.message, data.type);
    }
});

// ESC key handler
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        
        // Check if modal is open first
        const modal = document.getElementById('craftModal');
        if (modal && (modal.style.display === 'flex' || modal.classList.contains('show'))) {
            cancelCraft();
            return;
        }
        
        // Close UI
        try {
            fetch(`https://${GetParentResourceName()}/closeUI`, {
                method: 'POST',
                body: '{}'
            }).catch(() => {});
        } catch (e) {}
    }
});

// ═══════════════════════════════════════════════════════════════════════════════════════
// INITIALIZATION
// ═══════════════════════════════════════════════════════════════════════════════════════
document.addEventListener('DOMContentLoaded', function() {
    // Wrap static HTML hexagons in hex-wrap divs
    const hexContainer = document.querySelector('.level-hexagons');
    const rawHexes = document.querySelectorAll('.level-hex');
    
    rawHexes.forEach((hex, idx) => {
        if (!hex.parentElement.classList.contains('hex-wrap')) {
            const wrap = document.createElement('div');
            wrap.className = 'hex-wrap';
            hexContainer.replaceChild(wrap, hex);
            wrap.appendChild(hex);
            
            // Create XP label as sibling to hex
            const xpLabel = document.createElement('div');
            xpLabel.className = 'hex-xp-label';
            wrap.appendChild(xpLabel);
            
            // Set initial value based on hex state
            const iconHolder = hex.querySelector('.hex-icon');
            if (hex.classList.contains('completed')) {
                xpLabel.textContent = '✓';
                xpLabel.style.color = '#10b981';
                if (iconHolder) iconHolder.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>';
            } else if (hex.classList.contains('current')) {
                xpLabel.textContent = '65';
                xpLabel.style.color = '#3b82f6';
                if (iconHolder) iconHolder.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/></svg>';
            } else {
                xpLabel.textContent = '100';
                xpLabel.style.color = '#6b7280';
                if (iconHolder) iconHolder.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V8a5 5 0 0 1 10 0v3"/></svg>';
            }
        }
    });
});
