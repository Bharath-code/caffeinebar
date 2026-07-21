document.addEventListener('DOMContentLoaded', () => {
    // -------------------------------------------------------------------------
    // A/B Price Test Integration
    // -------------------------------------------------------------------------
    const proPriceVal = document.getElementById('pro-price-val');
    const proCheckoutLink = document.getElementById('pro-checkout-link');

    // Assign visitor to A/B pricing bucket
    let priceBucket = localStorage.getItem('caffeinebar_price_bucket');
    if (!priceBucket) {
        priceBucket = Math.random() < 0.5 ? 'low' : 'high';
        localStorage.setItem('caffeinebar_price_bucket', priceBucket);
    }

    // Set pricing based on assigned bucket
    if (priceBucket === 'low') {
        if (proPriceVal) proPriceVal.textContent = '$7.99';
        if (proCheckoutLink) proCheckoutLink.href = 'https://polar.sh/caffeinebar-pro-799';
    } else {
        if (proPriceVal) proPriceVal.textContent = '$9.99';
        if (proCheckoutLink) proCheckoutLink.href = 'https://polar.sh/caffeinebar-pro-999';
    }

    // -------------------------------------------------------------------------
    // Video Embed (Ambulance Reel) Click-to-Unmute Logic
    // -------------------------------------------------------------------------
    const video = document.getElementById('ambulance-reel');
    const unmuteBtn = document.getElementById('video-unmute-btn');

    if (video && unmuteBtn) {
        unmuteBtn.addEventListener('click', () => {
            if (video.muted) {
                video.muted = false;
                unmuteBtn.innerHTML = '🔊 Muted (click to mute)';
            } else {
                video.muted = true;
                unmuteBtn.innerHTML = '🔇 Unmuted (click to unmute)';
            }
        });
    }

    // -------------------------------------------------------------------------
    // Waitlist Form Submission
    // -------------------------------------------------------------------------
    const waitlistForm = document.getElementById('waitlist-form');
    const waitlistSuccess = document.getElementById('waitlist-success');

    if (waitlistForm) {
        waitlistForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const emailInput = document.getElementById('waitlist-email');
            if (emailInput && emailInput.value) {
                // In production, send to server. Here we show an elegant confirmation.
                waitlistForm.classList.add('hidden');
                waitlistSuccess.classList.remove('hidden');
                localStorage.setItem('caffeinebar_waitlist_registered', 'true');
            }
        });
    }

    // -------------------------------------------------------------------------
    // Caffeine Crash Predictor Math & Logic
    // -------------------------------------------------------------------------
    const drinkTypeSelect = document.getElementById('drink-type');
    const customMgGroup = document.getElementById('custom-mg-group');
    const customMgInput = document.getElementById('custom-mg');
    const drinkTimeSelect = document.getElementById('drink-time');
    const specificTimeGroup = document.getElementById('specific-time-group');
    const specificTimeInput = document.getElementById('specific-time');
    const addDrinkBtn = document.getElementById('add-drink-btn');
    const metabolismProfile = document.getElementById('metabolism-profile');
    const bedtimeInput = document.getElementById('bedtime');
    const drinksList = document.getElementById('drinks-list');

    // State
    let loggedDrinks = [
        { id: 1, name: 'Double Espresso', mg: 150, time: new Date(Date.now() - 2 * 60 * 60 * 1000) } // 2 hours ago baseline
    ];

    // Toggle custom fields
    drinkTypeSelect.addEventListener('change', () => {
        if (drinkTypeSelect.value === 'custom') {
            customMgGroup.classList.remove('hidden');
        } else {
            customMgGroup.classList.add('hidden');
        }
    });

    drinkTimeSelect.addEventListener('change', () => {
        if (drinkTimeSelect.value === 'custom-time') {
            specificTimeGroup.classList.remove('hidden');
            // Set current time as default
            const now = new Date();
            specificTimeInput.value = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
        } else {
            specificTimeGroup.classList.add('hidden');
        }
    });

    // Add drink
    addDrinkBtn.addEventListener('click', () => {
        let name = drinkTypeSelect.options[drinkTypeSelect.selectedIndex].text.split(' (')[0];
        let mg = parseInt(drinkTypeSelect.options[drinkTypeSelect.selectedIndex].getAttribute('data-mg'));
        
        if (drinkTypeSelect.value === 'custom') {
            mg = parseInt(customMgInput.value) || 0;
            name = `Custom Drink (${mg} mg)`;
        }

        let drinkDate = new Date();
        const timeOption = drinkTimeSelect.value;
        if (timeOption === 'custom-time') {
            const [hours, minutes] = specificTimeInput.value.split(':');
            drinkDate.setHours(parseInt(hours), parseInt(minutes), 0, 0);
            if (drinkDate > new Date()) {
                // If chosen time is future, assume it was yesterday
                drinkDate.setDate(drinkDate.getDate() - 1);
            }
        } else {
            const minutesAgo = parseInt(timeOption);
            drinkDate = new Date(Date.now() - minutesAgo * 60 * 1000);
        }

        if (mg > 0) {
            loggedDrinks.push({
                id: Date.now(),
                name,
                mg,
                time: drinkDate
            });
            updateUI();
        }
    });

    // Remove drink
    window.removeDrink = (id) => {
        loggedDrinks = loggedDrinks.filter(d => d.id !== id);
        updateUI();
    };

    // Calculate caffeine level at any given date
    function getCaffeineAt(targetDate) {
        let halfLife = 5.0; // Default normal
        if (metabolismProfile.value === 'fast') halfLife = 3.5;
        if (metabolismProfile.value === 'slow') halfLife = 7.0;

        let total = 0;
        loggedDrinks.forEach(drink => {
            const hoursSince = (targetDate - drink.time) / (1000 * 60 * 60);
            if (hoursSince >= 0) {
                total += drink.mg * Math.pow(0.5, hoursSince / halfLife);
            }
        });
        return total;
    }

    // Update UI components
    function updateUI() {
        // 1. Render Logged Drinks List
        drinksList.innerHTML = '';
        loggedDrinks.forEach(drink => {
            const timeStr = drink.time.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            const li = document.createElement('li');
            li.className = 'drink-item';
            li.innerHTML = `
                <div class="drink-info">
                    <strong>${drink.name}</strong>
                    <span style="color: var(--text-secondary); font-size: 0.75rem;">At ${timeStr} • ${drink.mg}mg</span>
                </div>
                <button class="drink-remove-btn" onclick="removeDrink(${drink.id})">×</button>
            `;
            drinksList.appendChild(li);
        });

        const now = new Date();
        const currentLevel = getCaffeineAt(now);

        // 2. Set current level element
        const valCurrent = document.getElementById('val-current');
        const statusText = document.getElementById('status-text');
        valCurrent.innerHTML = `${Math.round(currentLevel)} <span class="unit">mg</span>`;
        
        let status = 'Empty';
        let statusColor = 'var(--status-empty)';
        if (currentLevel > 150) {
            status = 'Over-Caffeinated ⚡️';
            statusColor = 'var(--status-danger)';
        } else if (currentLevel > 80) {
            status = 'Focused / Alert';
            statusColor = 'var(--status-active)';
        } else if (currentLevel > 20) {
            status = 'Mild Buzz';
            statusColor = 'var(--status-warning)';
        }
        statusText.textContent = status;
        statusText.style.color = statusColor;

        // 3. Predict Crash Window (when caffeine drops below 30mg after having been above it)
        const valCrash = document.getElementById('val-crash');
        const crashSub = document.getElementById('crash-sub');
        let crashTime = null;

        if (currentLevel >= 30) {
            // Find when it crosses below 30mg
            for (let offsetMinutes = 1; offsetMinutes < 24 * 60; offsetMinutes++) {
                const futureTime = new Date(now.getTime() + offsetMinutes * 60 * 1000);
                if (getCaffeineAt(futureTime) < 30) {
                    crashTime = futureTime;
                    break;
                }
            }
        }

        if (crashTime) {
            valCrash.textContent = crashTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            crashSub.textContent = 'Caffeine drops below active levels';
        } else {
            valCrash.textContent = '--:--';
            crashSub.textContent = currentLevel > 0 ? 'Remains above 30mg next 24h' : 'No caffeine active';
        }

        // 4. Next Coffee Window (when caffeine drops below 50mg but at least 6 hours before bedtime)
        const valNextCoffee = document.getElementById('val-next-coffee');
        const nextCoffeeSub = document.getElementById('next-coffee-sub');
        const [bedHours, bedMins] = bedtimeInput.value.split(':');
        const bedtimeToday = new Date();
        bedtimeToday.setHours(parseInt(bedHours), parseInt(bedMins), 0, 0);

        let nextCoffeeTime = null;
        if (currentLevel > 50) {
            for (let offsetMinutes = 1; offsetMinutes < 24 * 60; offsetMinutes++) {
                const futureTime = new Date(now.getTime() + offsetMinutes * 60 * 1000);
                if (getCaffeineAt(futureTime) <= 50) {
                    nextCoffeeTime = futureTime;
                    break;
                }
            }
        } else {
            nextCoffeeTime = now;
        }

        if (nextCoffeeTime) {
            const hoursToBedtime = (bedtimeToday - nextCoffeeTime) / (1000 * 60 * 60);
            if (hoursToBedtime < 6) {
                valNextCoffee.textContent = 'Skip';
                nextCoffeeSub.textContent = 'Too close to bedtime 🚫';
                nextCoffeeSub.style.color = 'var(--status-danger)';
            } else {
                valNextCoffee.textContent = nextCoffeeTime === now ? 'Now' : nextCoffeeTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
                nextCoffeeSub.textContent = 'Optimal window to stay alert';
                nextCoffeeSub.style.color = 'var(--text-secondary)';
            }
        } else {
            valNextCoffee.textContent = '--:--';
            nextCoffeeSub.textContent = 'N/A';
        }

        // 5. Sleep Warning (caffeine level at bedtime)
        const valBedtime = document.getElementById('val-bedtime');
        const sleepSub = document.getElementById('sleep-sub');
        const sleepCard = document.getElementById('sleep-card');
        const bedtimeLevel = getCaffeineAt(bedtimeToday);

        valBedtime.innerHTML = `${Math.round(bedtimeLevel)} <span class="unit">mg</span>`;
        if (bedtimeLevel > 50) {
            sleepSub.textContent = 'Ruin your sleep warning! ⚠️';
            sleepSub.style.color = 'var(--status-danger)';
            sleepCard.style.borderColor = 'var(--status-danger)';
        } else {
            sleepSub.textContent = 'Safe for sleep ✅';
            sleepSub.style.color = 'var(--status-active)';
            sleepCard.style.borderColor = 'var(--border-color)';
        }

        // 6. Draw Chart
        drawChart();
    }

    function drawChart() {
        const svg = document.getElementById('curve-chart');
        if (!svg) return;

        svg.innerHTML = '';
        const width = 500;
        const height = 220;
        const padding = 20;

        // Get 24 hour range starting from 8 hours ago to 16 hours ahead
        const startTime = new Date(Date.now() - 8 * 60 * 60 * 1000);
        const duration = 24 * 60 * 60 * 1000;

        // Find max caffeine level in this range for scaling
        let maxVal = 100;
        for (let i = 0; i <= 100; i++) {
            const t = new Date(startTime.getTime() + (duration * i / 1000));
            maxVal = Math.max(maxVal, getCaffeineAt(t));
        }
        maxVal = Math.ceil(maxVal / 50) * 50; // round up to multiple of 50

        // Draw horizontal grid lines
        for (let v = 50; v <= maxVal; v += 50) {
            const y = height - padding - ((v / maxVal) * (height - 2 * padding));
            const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
            line.setAttribute('x1', padding);
            line.setAttribute('y1', y);
            line.setAttribute('x2', width - padding);
            line.setAttribute('y2', y);
            line.setAttribute('stroke', 'rgba(255,255,255,0.05)');
            line.setAttribute('stroke-width', '1');
            svg.appendChild(line);
        }

        // Generate points for the path
        let points = [];
        for (let i = 0; i <= 100; i++) {
            const t = new Date(startTime.getTime() + (duration * i / 100));
            const val = getCaffeineAt(t);
            const x = padding + (i / 100) * (width - 2 * padding);
            const y = height - padding - ((val / maxVal) * (height - 2 * padding));
            points.push({ x, y });
        }

        // Create path string
        let pathD = `M ${points[0].x} ${points[0].y}`;
        for (let i = 1; i < points.length; i++) {
            pathD += ` L ${points[i].x} ${points[i].y}`;
        }

        // Draw fill area
        const fillPath = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        const fillD = `${pathD} L ${points[points.length-1].x} ${height - padding} L ${points[0].x} ${height - padding} Z`;
        fillPath.setAttribute('d', fillD);
        fillPath.setAttribute('fill', 'url(#chartGradient)');
        fillPath.setAttribute('opacity', '0.2');
        svg.appendChild(fillPath);

        // Draw main line path
        const pathElement = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        pathElement.setAttribute('d', pathD);
        pathElement.setAttribute('fill', 'none');
        pathElement.setAttribute('stroke', 'var(--primary)');
        pathElement.setAttribute('stroke-width', '3');
        svg.appendChild(pathElement);

        // Draw gradient definition
        const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
        const gradient = document.createElementNS('http://www.w3.org/2000/svg', 'linearGradient');
        gradient.setAttribute('id', 'chartGradient');
        gradient.setAttribute('x1', '0');
        gradient.setAttribute('y1', '0');
        gradient.setAttribute('x2', '0');
        gradient.setAttribute('y2', '1');
        
        const stop1 = document.createElementNS('http://www.w3.org/2000/svg', 'stop');
        stop1.setAttribute('offset', '0%');
        stop1.setAttribute('stop-color', 'var(--primary)');
        
        const stop2 = document.createElementNS('http://www.w3.org/2000/svg', 'stop');
        stop2.setAttribute('offset', '100%');
        stop2.setAttribute('stop-color', 'var(--primary)');
        stop2.setAttribute('stop-opacity', '0');
        
        gradient.appendChild(stop1);
        gradient.appendChild(stop2);
        defs.appendChild(gradient);
        svg.appendChild(defs);

        // Draw "current time" line
        const nowX = padding + ((Date.now() - startTime.getTime()) / duration) * (width - 2 * padding);
        if (nowX >= padding && nowX <= width - padding) {
            const curLine = document.createElementNS('http://www.w3.org/2000/svg', 'line');
            curLine.setAttribute('x1', nowX);
            curLine.setAttribute('y1', padding);
            curLine.setAttribute('x2', nowX);
            curLine.setAttribute('y2', height - padding);
            curLine.setAttribute('stroke', 'var(--secondary)');
            curLine.setAttribute('stroke-dasharray', '4,4');
            curLine.setAttribute('stroke-width', '1.5');
            svg.appendChild(curLine);

            const curVal = getCaffeineAt(new Date());
            const curY = height - padding - ((curVal / maxVal) * (height - 2 * padding));
            const curCircle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
            curCircle.setAttribute('cx', nowX);
            curCircle.setAttribute('cy', curY);
            curCircle.setAttribute('r', '5');
            curCircle.setAttribute('fill', 'var(--secondary)');
            svg.appendChild(curCircle);
        }

        // Update timeline text labels below the chart
        const timelineLabels = document.querySelector('.chart-labels');
        if (timelineLabels) {
            timelineLabels.innerHTML = '';
            const step = duration / 4;
            for (let i = 0; i <= 4; i++) {
                const t = new Date(startTime.getTime() + i * step);
                const span = document.createElement('span');
                span.textContent = t.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false });
                timelineLabels.appendChild(span);
            }
        }
    }

    // -------------------------------------------------------------------------
    // Share Functionality
    // -------------------------------------------------------------------------
    const shareBtn = document.getElementById('share-btn');
    if (shareBtn) {
        shareBtn.addEventListener('click', () => {
            const currentLevel = Math.round(getCaffeineAt(new Date()));
            const crashVal = document.getElementById('val-crash').textContent;
            const nextCoffeeVal = document.getElementById('val-next-coffee').textContent;
            
            const shareText = `☕️ Caffeine Crash Predictor:\n` +
                              `• Current Level: ${currentLevel} mg\n` +
                              `• Crash Predicted: ${crashVal}\n` +
                              `• Next Coffee: ${nextCoffeeVal}\n` +
                              `Track your coffee & sleep zones at caffeinebar.app`;

            navigator.clipboard.writeText(shareText).then(() => {
                const originalText = shareBtn.innerHTML;
                shareBtn.innerHTML = '✅ Clipboard Copied!';
                setTimeout(() => {
                    shareBtn.innerHTML = originalText;
                }, 2000);
            }).catch(err => {
                console.error('Could not copy text: ', err);
            });
        });
    }

    // Listen to settings/inputs dynamically
    metabolismProfile.addEventListener('change', updateUI);
    bedtimeInput.addEventListener('change', updateUI);

    // Initial render
    updateUI();
});
