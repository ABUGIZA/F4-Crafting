let selectedItem = 0;
let playerLevel = 1;
let items = [];
let inventory = {};
let countdownInterval = null;

let isCrafting = false;
let craftingItemIndex = -1;
let craftingQuantity = 1;
let craftingTimeLeft = 0;
let craftingTotalTime = 0;
let uiCurrentTableId = null;
let craftingTableId = null;
let queueItems = [];
let queueTimer = null;
let queueActionLock = false;

function selectItem(index) {
    if (!items[index]) return;
    
    if (items[index].level > playerLevel) {
        return;
    }
    
    document.querySelectorAll('.item-card').forEach(card => {
        card.classList.remove('active');
    });
    
    document.querySelectorAll('.item-card')[index].classList.add('active');
    
    const itemNameEl = document.querySelector('.item-name');
    const itemPreviewEl = document.querySelector('.item-preview');
    
    if (itemNameEl) itemNameEl.textContent = items[index].name;
    if (itemPreviewEl) {
        itemPreviewEl.src = items[index].image;
        itemPreviewEl.alt = items[index].name;
    }
    
    selectedItem = index;
    
    updateInventoryDisplay();
    
}

function updateItemLocks() {
    const itemCards = document.querySelectorAll('.item-card');
    itemCards.forEach((card, index) => {
        if (items[index].level > playerLevel) {
            card.classList.add('locked');
            
            if (!card.querySelector('.lock-icon')) {
                const lockIcon = document.createElement('div');
                lockIcon.className = 'lock-icon';
                lockIcon.innerHTML = '<svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V8a5 5 0 0 1 10 0v3"/></svg>';
                card.appendChild(lockIcon);
            }
            
            card.onclick = null;
        } else {
            card.classList.remove('locked');
            
            const lockIcon = card.querySelector('.lock-icon');
            if (lockIcon) {
                lockIcon.remove();
            }
            
            card.onclick = () => selectItem(index);
        }
    });
}

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

function updateInventoryDisplay() {
    if (items.length === 0 || !items[selectedItem]) return;
    
    const requirements = items[selectedItem].requirements || [];
    const resourcesContainer = document.querySelector('.resources-grid');
    if (!resourcesContainer) return;
    
    resourcesContainer.innerHTML = '';
    
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
        
        const isBlueprint = req.metadata && Object.keys(req.metadata).length > 0;
        let metadataText = '';
        if (isBlueprint) {
            const blueprintType = req.metadata.type || 'unknown';
            const displayType = blueprintType.charAt(0).toUpperCase() + blueprintType.slice(1).replace('_', ' ');
            metadataText = `<div class="bg-blue-900/30 border border-blue-500/30 rounded px-1 py-0.5 mb-2 max-w-fit mx-auto">
                <p class="text-xs text-blue-300 font-medium text-center">${displayType} Blueprint</p>
            </div>`;
        }
        
        const resourceSlot = document.createElement('div');
        resourceSlot.className = 'resource-slot';
        resourceSlot.innerHTML = `
            <img src="nui://ox_inventory/web/images/${req.item}.png" alt="${req.label}" class="w-12 h-12 mx-auto mb-3">
            <h3 class="text-white font-semibold text-sm mb-1">${req.label}</h3>
            ${metadataText}
            <p class="text-xs secondary-text mb-2">REQUIRED: ${needAmount}</p>
            <p class="font-orbitron text-lg font-bold ${hasEnough ? 'text-green-400' : 'text-red-400'}">${hasAmount}</p>
        `;
        
        resourcesContainer.appendChild(resourceSlot);
    });
}

function escapeHtml(value) {
    return String(value ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function formatDuration(seconds) {
    const safeSeconds = Math.max(0, Math.floor(seconds || 0));
    if (safeSeconds >= 3600) {
        const hours = Math.floor(safeSeconds / 3600);
        const minutes = Math.floor((safeSeconds % 3600) / 60);
        return `${hours}h ${minutes}m`;
    }

    if (safeSeconds >= 60) {
        const minutes = Math.floor(safeSeconds / 60);
        const secs = safeSeconds % 60;
        return secs > 0 ? `${minutes}m ${secs}s` : `${minutes}m`;
    }

    return `${safeSeconds}s`;
}

function renderQueue() {
    const queueList = document.getElementById('queueList');
    if (!queueList) return;

    if (!Array.isArray(queueItems) || queueItems.length === 0) {
        queueList.innerHTML = `<div class="queue-empty">No crafted items on this table yet.</div>`;
        return;
    }

    const now = Math.floor(Date.now() / 1000);

    queueItems.forEach(entry => {
        const readyAt = Number(entry.readyAt || now);
        const remaining = Math.max(0, readyAt - now);
        entry.timeLeft = remaining;
        entry.ready = remaining <= 0;
    });

    queueList.innerHTML = queueItems.map(entry => {
        const readyClass = entry.ready ? 'ready' : 'pending';
        const statusText = entry.ready ? 'Ready to collect' : `Ready in ${formatDuration(entry.timeLeft)}`;
        const buttonState = entry.ready ? '' : 'disabled';

        return `
            <div class="queue-row ${readyClass}">
                <div class="queue-item-meta">
                    <img src="nui://ox_inventory/web/images/${escapeHtml(entry.item)}.png" alt="${escapeHtml(entry.label)}" class="queue-item-image">
                    <div class="queue-item-text">
                        <div class="queue-item-name">${escapeHtml(entry.label)}</div>
                        <div class="queue-item-details">Qty: ${Number(entry.quantity || 1)}</div>
                        <div class="queue-item-status">${statusText}</div>
                    </div>
                </div>
                <button class="queue-take-btn" data-queue-id="${escapeHtml(entry.id)}" ${buttonState}>Take</button>
            </div>
        `;
    }).join('');

    queueList.querySelectorAll('.queue-take-btn').forEach(button => {
        button.addEventListener('click', () => {
            const queueId = button.getAttribute('data-queue-id');
            if (queueId) {
                takeQueuedItem(queueId);
            }
        });
    });
}

function stopQueueTimer() {
    if (queueTimer) {
        clearInterval(queueTimer);
        queueTimer = null;
    }
}

function startQueueTimer() {
    stopQueueTimer();
    queueTimer = setInterval(() => {
        if (Array.isArray(queueItems) && queueItems.length > 0) {
            renderQueue();
        }
    }, 1000);
}

function takeQueuedItem(queueId) {
    if (!queueId || queueActionLock) return;

    queueActionLock = true;

    fetch(`https://${GetParentResourceName()}/claimQueuedItem`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ queueId })
    })
        .then(resp => resp.json())
        .then(result => {
            if (result && result.success) {
                queueItems = queueItems.filter(entry => String(entry.id) !== String(queueId));
                renderQueue();
            }
        })
        .catch(() => {})
        .finally(() => {
            queueActionLock = false;
        });
}

function craftItem() {
    if (countdownInterval) {
        showNotification('Crafting in progress, please wait...', 'error');
        return;
    }
    
    const quantity = parseInt(document.getElementById('quantity').value);
    const itemName = items[selectedItem].name;
    const itemImage = items[selectedItem].image;
    
    const modal = document.getElementById('craftModal');
    if (!modal) return;
    
    document.getElementById('modalItemImage').src = itemImage;
    document.getElementById('modalItemImage').alt = itemName;
    document.getElementById('modalItemName').textContent = itemName;
    document.getElementById('modalQuantityValue').textContent = quantity;
    
    modal.style.display = 'flex';
    modal.style.visibility = 'visible';
    modal.style.opacity = '1';
    modal.classList.add('show');
}

function confirmCraft() {
    const quantity = parseInt(document.getElementById('quantity').value);
    
    const modal = document.getElementById('craftModal');
    modal.style.display = 'none';
    modal.classList.remove('show');
    
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

function cancelCraft() {
    const modal = document.getElementById('craftModal');
    modal.style.display = 'none';
    modal.classList.remove('show');
}

function startCountdown(totalTime, tableId = null) {
    const targetTableId = Number(tableId ?? uiCurrentTableId ?? 0) || null;
    const currentTableNum = Number(uiCurrentTableId ?? 0) || null;

    if (targetTableId && currentTableNum && targetTableId !== currentTableNum) {
        return;
    }

    if (isCrafting && countdownInterval) {
        return;
    }
    
    if (countdownInterval) {
        clearInterval(countdownInterval);
        countdownInterval = null;
    }
    
    const item = items[selectedItem];
    const quantity = parseInt(document.getElementById('quantity').value) || 1;
    
    if (!item) return;
    
    isCrafting = true;
    craftingTableId = targetTableId || currentTableNum;
    craftingItemIndex = selectedItem;
    craftingQuantity = quantity;
    craftingTimeLeft = totalTime;
    craftingTotalTime = totalTime;
    
    let timeDisplay = '';
    if (totalTime >= 60) {
        const minutes = Math.floor(totalTime / 60);
        const seconds = totalTime % 60;
        timeDisplay = seconds > 0 ? `${minutes}m ${seconds}s` : `${minutes}m`;
    } else {
        timeDisplay = `${totalTime}s`;
    }
    
    const progressContainer = document.getElementById('craftingProgressContainer');
    const progressPanel = document.getElementById('craftingProgressPanel');
    
    if (progressContainer && progressPanel) {
        progressPanel.innerHTML = `
            <div class="flex items-center space-x-4">
                <div class="flex-shrink-0">
                    <img src="${item.image}" alt="${item.name}" class="w-12 h-12 rounded-lg border border-gray-600">
                </div>
                
                <div class="flex-1 min-w-0">
                    <h3 class="text-white font-semibold text-sm mb-1 truncate">${item.name}</h3>
                    <p class="text-gray-300 text-xs">Qty: ${quantity}</p>
                </div>
                
                <div class="flex-shrink-0 ml-2">
                    <div class="relative w-12 h-12">
                        <svg class="w-12 h-12 transform -rotate-90" viewBox="0 0 36 36">
                            <path class="text-gray-600" stroke="currentColor" stroke-width="2" fill="none"
                                d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"/>
                            <path id="progressCircle" class="text-white" stroke="currentColor" stroke-width="2" fill="none"
                                stroke-linecap="round"
                                d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"/>
                        </svg>
                        <div class="absolute inset-0 flex items-center justify-center">
                            <span id="progressTimeText" class="text-white text-xs font-bold">${timeDisplay}</span>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        progressContainer.style.display = 'block';
    }
    
    let timeLeft = totalTime;
    const progressTimeText = document.getElementById('progressTimeText');
    const progressCircle = document.getElementById('progressCircle');
    
    if (!progressTimeText || !progressCircle) return;
    
    updateCountdownDisplay(timeLeft, totalTime);
    
    countdownInterval = setInterval(() => {
        timeLeft--;
        craftingTimeLeft = timeLeft;
        updateCountdownDisplay(timeLeft, totalTime);
        
        if (timeLeft <= 0) {
            stopCountdown();
        }
    }, 1000);
}

function updateCountdownDisplay(timeLeft, totalTime) {
    const progressTimeText = document.getElementById('progressTimeText');
    const progressCircle = document.getElementById('progressCircle');
    
    if (!progressTimeText || !progressCircle) return;
    
    const progress = ((totalTime - timeLeft) / totalTime) * 100;
    const circumference = 2 * Math.PI * 15.9155;
    const strokeDasharray = circumference;
    const strokeDashoffset = circumference - (progress / 100) * circumference;
    
    progressCircle.style.transition = 'stroke-dashoffset 1s ease-out, stroke 0.3s ease-out';
    progressCircle.style.strokeDasharray = strokeDasharray;
    progressCircle.style.strokeDashoffset = strokeDashoffset;
    
    if (timeLeft > 0) {
        let timeDisplay = '';
        if (timeLeft >= 60) {
            const minutes = Math.floor(timeLeft / 60);
            const seconds = timeLeft % 60;
            timeDisplay = seconds > 0 ? `${minutes}m ${seconds}s` : `${minutes}m`;
        } else {
            timeDisplay = `${timeLeft}s`;
        }
        
        progressTimeText.textContent = timeDisplay;
        
        if (timeLeft <= 3) {
            progressCircle.className = 'text-red-400 animate-pulse';
            progressTimeText.className = 'text-red-400 text-xs font-bold';
        } else if (timeLeft <= 10) {
            progressCircle.className = 'text-orange-400';
            progressTimeText.className = 'text-orange-400 text-xs font-bold';
        } else {
            progressCircle.className = 'text-white';
            progressTimeText.className = 'text-white text-xs font-bold';
        }
    } else {
        progressCircle.className = 'text-green-400';
        progressTimeText.textContent = '0';
        progressTimeText.className = 'text-green-400 text-xs font-bold';
        
        progressCircle.style.strokeDashoffset = 0;
    }
}

function stopCountdown(immediate = false) {
    if (countdownInterval) {
        clearInterval(countdownInterval);
        countdownInterval = null;
    }
    
    isCrafting = false;
    craftingItemIndex = -1;
    craftingQuantity = 1;
    craftingTimeLeft = 0;
    craftingTotalTime = 0;
    craftingTableId = null;

    const progressContainer = document.getElementById('craftingProgressContainer');
    if (!progressContainer) {
        return;
    }
    
    if (immediate) {
        progressContainer.style.display = 'none';
        return;
    }

    setTimeout(() => {
        progressContainer.style.display = 'none';
    }, 1500);
}

function restoreCraftingState() {
    if (!isCrafting || craftingTimeLeft <= 0 || craftingItemIndex < 0) {
        return;
    }

    const currentTableNum = Number(uiCurrentTableId ?? 0) || null;
    const craftingTableNum = Number(craftingTableId ?? 0) || null;
    if (craftingTableNum && currentTableNum && craftingTableNum !== currentTableNum) {
        return;
    }
    
    if (countdownInterval) {
        return;
    }
    
    const item = items[craftingItemIndex];
    if (item) {
            let timeDisplay = '';
            if (craftingTimeLeft >= 60) {
                const minutes = Math.floor(craftingTimeLeft / 60);
                const seconds = craftingTimeLeft % 60;
                timeDisplay = seconds > 0 ? `${minutes}m ${seconds}s` : `${minutes}m`;
            } else {
                timeDisplay = `${craftingTimeLeft}s`;
            }
            
            const progressContainer = document.getElementById('craftingProgressContainer');
            const progressPanel = document.getElementById('craftingProgressPanel');
            
            if (progressContainer && progressPanel) {
                progressPanel.innerHTML = `
                    <div class="flex items-center space-x-4">
                        <div class="flex-shrink-0">
                            <img src="${item.image}" alt="${item.name}" class="w-12 h-12 rounded-lg border border-gray-600">
                        </div>
                        
                        <div class="flex-1 min-w-0">
                            <h3 class="text-white font-semibold text-sm mb-1 truncate">${item.name}</h3>
                            <p class="text-gray-300 text-xs">Qty: ${craftingQuantity}</p>
                        </div>
                        
                        <div class="flex-shrink-0 ml-2">
                            <div class="relative w-12 h-12">
                                <svg class="w-12 h-12 transform -rotate-90" viewBox="0 0 36 36">
                                    <path class="text-gray-600" stroke="currentColor" stroke-width="2" fill="none"
                                        d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"/>
                                    <path id="progressCircle" class="text-white" stroke="currentColor" stroke-width="2" fill="none"
                                        stroke-linecap="round"
                                        d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"/>
                                </svg>
                                <div class="absolute inset-0 flex items-center justify-center">
                                    <span id="progressTimeText" class="text-white text-xs font-bold">${timeDisplay}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                `;
                
                progressContainer.style.display = 'block';
                
                setTimeout(() => {
                    updateCountdownDisplay(craftingTimeLeft, craftingTotalTime);
                }, 100);
                
                countdownInterval = setInterval(() => {
                    craftingTimeLeft--;
                    updateCountdownDisplay(craftingTimeLeft, craftingTotalTime);
                    
                    if (craftingTimeLeft <= 0) {
                        stopCountdown();
                    }
                }, 1000);
            }
    }
}

function increaseQuantity() {
    const input = document.getElementById('quantity');
    const currentValue = parseInt(input.value);
    const maxValue = parseInt(input.max);
    
    if (currentValue < maxValue) {
        input.value = currentValue + 1;
    }
}

function decreaseQuantity() {
    const input = document.getElementById('quantity');
    const currentValue = parseInt(input.value);
    const minValue = parseInt(input.min);
    
    if (currentValue > minValue) {
        input.value = currentValue - 1;
    }
}

function updateLevelDisplay(level, xp, xpRequired, xpPerHex = 100) {
    const levelStart = document.querySelector('.level-start');
    const levelEnd = document.querySelector('.level-end');
    
    if (levelStart) levelStart.textContent = level;
    if (levelEnd) levelEnd.textContent = level + 1;
    
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
        
        const wrap = cell.parentElement;
        let xpLabel = wrap.querySelector('.hex-xp-label');
        if (!xpLabel) {
            xpLabel = document.createElement('div');
            xpLabel.className = 'hex-xp-label';
            wrap.appendChild(xpLabel);
        }
        
        if (idx < completed) {
            cell.classList.add('completed');
            if (iconHolder) iconHolder.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>';
            xpLabel.textContent = '✓';
            xpLabel.style.color = '#10b981';
        } else if (idx === completed) {
            cell.classList.add('current', 'active');
            cell.style.setProperty('--xp', ratio.toString());
            cell.title = `XP ${Math.round(xpInPart)}/${Math.round(part)}`;
            if (iconHolder) iconHolder.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="4"/></svg>';
            const remaining = Math.ceil(part - xpInPart);
            xpLabel.textContent = remaining;
            xpLabel.style.color = '#3b82f6';
        } else {
            cell.classList.add('locked');
            if (iconHolder) iconHolder.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="10" rx="2"/><path d="M7 11V8a5 5 0 0 1 10 0v3"/></svg>';
            xpLabel.textContent = Math.round(part);
            xpLabel.style.color = '#6b7280';
        }
    });
}

function showNotification(message, type = 'info') {
    const existingNotifications = document.querySelectorAll('.ui-notification');
    existingNotifications.forEach(notification => notification.remove());
    
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
    
    const uiScale = document.querySelector('.ui-scale');
    if (uiScale) {
        uiScale.appendChild(notification);
        
        setTimeout(() => {
            notification.classList.add('show');
        }, 10);
        
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

function GetParentResourceName() {
    let resourceName = 'F4-Crafting';
    if (window.location.href.includes('://nui-')) {
        resourceName = window.location.href.split('://nui-')[1].split('/')[0];
    }
    return resourceName;
}

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'open') {
        const nextTableId = Number(data.tableId ?? 0) || null;
        const previousTableId = Number(uiCurrentTableId ?? 0) || null;
        if (previousTableId !== nextTableId) {
            stopCountdown(true);
        }
        uiCurrentTableId = nextTableId;

        items = data.items || [];
        playerLevel = (data.playerLevel !== undefined && data.playerLevel !== null) ? data.playerLevel : 0;
        inventory = data.inventory || {};
        const xpRequired = data.xpRequired || 600;
        const xpPerHex = data.xpPerHex || 100;
        const playerXP = (data.playerXP !== undefined && data.playerXP !== null) ? data.playerXP : 0;
        queueItems = Array.isArray(data.queue) ? data.queue : [];
        
        renderItems();
        updateInventoryDisplay();
        renderQueue();
        startQueueTimer();
        updateLevelDisplay(playerLevel, playerXP, xpRequired, xpPerHex);
        
        const wrapper = document.querySelector('.ui-scale-wrapper');
        if (wrapper) wrapper.style.display = 'flex';
        
        selectItem(0);
        
        setTimeout(() => {
            restoreCraftingState();
        }, 200);
    } else if (data.action === 'close') {
        const wrapper = document.querySelector('.ui-scale-wrapper');
        if (wrapper) wrapper.style.display = 'none';
        stopCountdown(true);
        uiCurrentTableId = null;
        queueItems = [];
        renderQueue();
        stopQueueTimer();
    } else if (data.action === 'updateInventory') {
        inventory = data.inventory || {};
        updateInventoryDisplay();
    } else if (data.action === 'updateQueue') {
        queueItems = Array.isArray(data.queue) ? data.queue : [];
        renderQueue();
    } else if (data.action === 'updateLevel') {
        const xpRequired = data.xpRequired || 600;
        const xpPerHex = data.xpPerHex || 100;
        updateLevelDisplay(data.level, data.xp, xpRequired, xpPerHex);
        playerLevel = data.level;
        updateItemLocks();
    } else if (data.action === 'showNotification') {
        showNotification(data.message, data.type);
    } else if (data.action === 'startCountdown') {
        startCountdown(data.time, data.tableId);
    } else if (data.action === 'stopCountdown') {
        stopCountdown(true);
    }
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        event.preventDefault();
        event.stopPropagation();
        
        const modal = document.getElementById('craftModal');
        if (modal && (modal.style.display === 'flex' || modal.classList.contains('show'))) {
            cancelCraft();
            return;
        }
        
        try {
            fetch(`https://${GetParentResourceName()}/closeUI`, {
                method: 'POST',
                body: '{}'
            }).catch(() => {});
        } catch (e) {}
    }
});

document.addEventListener('DOMContentLoaded', function() {
    const hexContainer = document.querySelector('.level-hexagons');
    const rawHexes = document.querySelectorAll('.level-hex');
    
    rawHexes.forEach((hex, idx) => {
        if (!hex.parentElement.classList.contains('hex-wrap')) {
            const wrap = document.createElement('div');
            wrap.className = 'hex-wrap';
            hexContainer.replaceChild(wrap, hex);
            wrap.appendChild(hex);
            
            const xpLabel = document.createElement('div');
            xpLabel.className = 'hex-xp-label';
            wrap.appendChild(xpLabel);
            
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

    renderQueue();
});
