const appState = {
    cameras: [],
    dashboard: {},
    evidence: [],
    filter: 'all',
    search: '',
    section: 'dashboard'
};

function postNui(action, data = {}) {
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'bergischland_cctv';
    fetch(`https://${resourceName}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    }).catch(() => {});
}

function renderDashboard() {
    document.getElementById('statTotal').textContent = appState.dashboard.total || 0;
    document.getElementById('statOnline').textContent = appState.dashboard.online || 0;
    document.getElementById('statOffline').textContent = appState.dashboard.offline || 0;
    document.getElementById('statDamaged').textContent = appState.dashboard.damaged || 0;
    document.getElementById('statRecordings').textContent = appState.dashboard.recordings || 0;
    document.getElementById('statEvidence').textContent = appState.dashboard.evidence || 0;
}

function getFilteredCameras() {
    const query = appState.search.trim().toLowerCase();
    return appState.cameras.filter((camera) => {
        const matchesSearch = !query || camera.name.toLowerCase().includes(query) || String(camera.id).includes(query);
        const matchesFilter = appState.filter === 'all' ||
            (appState.filter === 'police' && camera.type === 'police') ||
            (appState.filter === 'business' && camera.type === 'business') ||
            (appState.filter === 'public' && camera.type === 'public') ||
            camera.status === appState.filter;

        return matchesSearch && matchesFilter;
    });
}

function renderCameraList() {
    const cameraListEl = document.getElementById('cameraList');
    const filtered = getFilteredCameras();

    if (!filtered.length) {
        cameraListEl.innerHTML = '<div class="empty-card"><h3>Keine Kameras gefunden</h3><p>Keine Ergebnisse zu den aktuellen Filtern.</p></div>';
        return;
    }

    cameraListEl.innerHTML = filtered.map((camera) => {
        let statusClass = 'online';
        if (camera.status === 'OFFLINE') statusClass = 'offline';
        if (camera.status === 'DAMAGED') statusClass = 'damaged';

        return `
            <div class="camera-card">
                <div class="camera-head">
                    <h4>Kamera #${String(camera.id).padStart(3, '0')}</h4>
                    <span class="badge ${statusClass}">${camera.status || 'ONLINE'}</span>
                </div>
                <div class="camera-meta">${camera.name || 'Unbenannt'}</div>
                <div class="camera-meta">Typ: ${camera.type || 'public'} · Sichtweite: ${camera.range || 35}m</div>
                <div class="camera-actions">
                    <button class="action-button primary" data-camera-action="open" data-camera-id="${camera.id}">ANSEHEN</button>
                    <button class="action-button" data-camera-action="details" data-camera-id="${camera.id}">DETAILS</button>
                </div>
            </div>
        `;
    }).join('');
}

function renderEvidence() {
    const evidenceListEl = document.getElementById('evidenceList');
    if (!appState.evidence.length) {
        evidenceListEl.innerHTML = '<div class="empty-card"><h3>Keine Beweismittel</h3><p>Es wurden noch keine gesicherten Beweismittel erzeugt.</p></div>';
        return;
    }

    evidenceListEl.innerHTML = appState.evidence.map((item) => `
        <div class="evidence-card">
            <strong>Beweismittel #${item.id || 'N/A'}</strong>
            <span>Offizier: ${item.officer_name || 'Unbekannt'}</span>
            <span>Grund: ${item.reason || 'Nicht angegeben'}</span>
            <span>AKTE: ${item.case_number || 'N/A'}</span>
        </div>
    `).join('');
}

function setSection(sectionName) {
    appState.section = sectionName;
    document.querySelectorAll('.nav-item').forEach((button) => {
        button.classList.toggle('active', button.dataset.section === sectionName);
    });
    document.querySelectorAll('[data-section-view]').forEach((section) => {
        section.classList.toggle('active', section.dataset.sectionView === sectionName);
    });
}

function updateFromPayload(payload) {
    if (!payload) return;

    if (payload.dashboard) {
        appState.dashboard = payload.dashboard;
    }

    if (payload.cameras) {
        appState.cameras = payload.cameras;
    }

    if (payload.evidence) {
        appState.evidence = payload.evidence;
    }

    renderDashboard();
    renderCameraList();
    renderEvidence();
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data) return;

    if (data.action === 'open') {
        document.getElementById('cctv-app').classList.remove('hidden');
        return;
    }

    if (data.action === 'close') {
        document.getElementById('cctv-app').classList.add('hidden');
        return;
    }

    if (data.action === 'setData') {
        updateFromPayload(data.payload || {});
    }
});

document.querySelectorAll('.nav-item').forEach((button) => {
    button.addEventListener('click', () => setSection(button.dataset.section));
});

document.querySelectorAll('.filter').forEach((button) => {
    button.addEventListener('click', () => {
        appState.filter = button.dataset.filter;
        document.querySelectorAll('.filter').forEach((item) => item.classList.toggle('active', item === button));
        renderCameraList();
    });
});

document.getElementById('cameraSearch').addEventListener('input', (event) => {
    appState.search = event.target.value;
    renderCameraList();
});

document.getElementById('closeNuiBtn').addEventListener('click', () => {
    postNui('cctv:nui:close', {});
});

document.getElementById('createCameraBtn').addEventListener('click', () => {
    postNui('cctv:nui:createCamera', {
        name: 'Neue Kamera',
        type: 'public',
        range: 35,
        fov: 70,
        x: 0,
        y: 0,
        z: 0,
        rotation: 0,
        status: 'ONLINE'
    });
});

document.getElementById('cameraList').addEventListener('click', (event) => {
    const actionElement = event.target.closest('[data-camera-action]');
    if (!actionElement) return;

    const cameraId = actionElement.dataset.cameraId;
    const action = actionElement.dataset.cameraAction;

    if (action === 'open') {
        postNui('cctv:nui:openCamera', { cameraId });
    }

    if (action === 'details') {
        const camera = appState.cameras.find((item) => String(item.id) === String(cameraId));
        if (camera) {
            document.getElementById('cameraTitle').textContent = `Kamera #${String(camera.id).padStart(3, '0')} · ${camera.name || 'Unbenannt'}`;
            document.getElementById('cameraView').classList.remove('hidden');
        }
    }
});

document.getElementById('exitCameraBtn').addEventListener('click', () => {
    document.getElementById('cameraView').classList.add('hidden');
    postNui('cctv:nui:close', {});
});

document.getElementById('nextCameraBtn').addEventListener('click', () => {
    const current = appState.cameras[0];
    if (current) {
        postNui('cctv:nui:openCamera', { cameraId: current.id });
    }
});

document.getElementById('prevCameraBtn').addEventListener('click', () => {
    const current = appState.cameras[0];
    if (current) {
        postNui('cctv:nui:openCamera', { cameraId: current.id });
    }
});

setSection('dashboard');
renderDashboard();
renderCameraList();
renderEvidence();
