const app = document.getElementById('app');
const businessGrid = document.getElementById('businessGrid');
const emptyState = document.getElementById('emptyState');
const searchInput = document.getElementById('searchInput');
const categoryFilter = document.getElementById('categoryFilter');
const hiringOnly = document.getElementById('hiringOnly');
const closeBtn = document.getElementById('closeBtn');
const switchToPublicBtn = document.getElementById('switchToPublicBtn');
const switchToAdminBtn = document.getElementById('switchToAdminBtn');
const publicView = document.getElementById('publicView');
const adminView = document.getElementById('adminView');
const editorList = document.getElementById('editorList');
const newBusinessBtn = document.getElementById('newBusinessBtn');
const saveBusinessBtn = document.getElementById('saveBusinessBtn');
const deleteBusinessBtn = document.getElementById('deleteBusinessBtn');
const backToPublicBtn = document.getElementById('backToPublicBtn');
const editorTitle = document.getElementById('editorTitle');
const modeEyebrow = document.getElementById('modeEyebrow');
const modeTitle = document.getElementById('modeTitle');
const modeDescription = document.getElementById('modeDescription');

const fieldId = document.getElementById('fieldId');
const fieldLabel = document.getElementById('fieldLabel');
const fieldCategory = document.getElementById('fieldCategory');
const fieldStatus = document.getElementById('fieldStatus');
const fieldOwner = document.getElementById('fieldOwner');
const fieldContact = document.getElementById('fieldContact');
const fieldLocation = document.getElementById('fieldLocation');
const fieldHiring = document.getElementById('fieldHiring');
const fieldImage = document.getElementById('fieldImage');
const fieldX = document.getElementById('fieldX');
const fieldY = document.getElementById('fieldY');
const fieldZ = document.getElementById('fieldZ');
const fieldDescription = document.getElementById('fieldDescription');
const previewImage = document.getElementById('previewImage');
const previewLabel = document.getElementById('previewLabel');
const previewMeta = document.getElementById('previewMeta');

let businesses = [];
let filtered = [];
let isAdmin = false;
let categories = [];
let defaultImage = '';
let starterMessage = 'Visit the Location to apply for a job at the door!';
let selectedEditorId = null;
let adminPermissions = ['god', 'admin'];
let currentMode = 'public';

function post(endpoint, body = {}) {
  fetch(`https://${GetParentResourceName()}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(body)
  });
}

function setVisible(state) {
  app.classList.toggle('hidden', !state);
}

function setMode(mode) {
  currentMode = mode === 'admin' ? 'admin' : 'public';
  publicView.classList.toggle('hidden', currentMode !== 'public');
  adminView.classList.toggle('hidden', currentMode !== 'admin');

  const adminAllowed = isAdmin === true;
  switchToAdminBtn.classList.toggle('hidden', !adminAllowed || currentMode === 'admin');
  switchToPublicBtn.classList.toggle('hidden', !adminAllowed || currentMode === 'public');

  if (currentMode === 'admin') {
    modeEyebrow.textContent = 'Business Directory Administration';
    modeTitle.textContent = 'Admin Business Panel';
    modeDescription.textContent = 'Add, edit, and remove businesses that appear on the public board.';
  } else {
    modeEyebrow.textContent = 'City Starter Directory';
    modeTitle.textContent = 'Business Introduction';
    modeDescription.textContent = 'Browse local businesses and head to their location to apply in person.';
  }
}

function populateCategories() {
  categoryFilter.innerHTML = '<option value="all">All Categories</option>';
  fieldCategory.innerHTML = '';

  categories.forEach(category => {
    const a = document.createElement('option');
    a.value = category;
    a.textContent = category;
    categoryFilter.appendChild(a);

    const b = document.createElement('option');
    b.value = category;
    b.textContent = category;
    fieldCategory.appendChild(b);
  });
}

function statusBadge(business) {
  return business.hiring ? 'Hiring' : (business.status || 'Open');
}

function filterBusinesses() {
  const term = searchInput.value.trim().toLowerCase();
  const category = categoryFilter.value;
  const hiring = hiringOnly.checked;

  filtered = businesses.filter((business) => {
    const haystack = [business.label, business.owner, business.location, business.description, business.contact, business.category]
      .join(' ')
      .toLowerCase();

    const matchesTerm = !term || haystack.includes(term);
    const matchesCategory = category === 'all' || business.category === category;
    const matchesHiring = !hiring || business.hiring === true;

    return matchesTerm && matchesCategory && matchesHiring;
  });

  renderBusinessGrid();
}

function renderBusinessGrid() {
  businessGrid.innerHTML = '';
  emptyState.classList.toggle('hidden', filtered.length > 0);

  filtered.forEach((business) => {
    const card = document.createElement('div');
    card.className = 'business-card';
    card.innerHTML = `
      <img src="${business.image || defaultImage}" alt="${business.label}">
      <div class="business-card-body">
        <div class="card-head">
          <div class="card-title">${business.label || 'Unnamed Business'}</div>
          <div class="badge ${business.hiring ? 'hiring' : 'normal'}">${statusBadge(business)}</div>
        </div>
        <div class="card-meta">${business.category || 'Other'} â€¢ Owner: ${business.owner || 'Unassigned'}</div>
        <div class="card-meta">${business.location || 'Unknown'} â€¢ ${business.contact || 'N/A'}</div>
        <div class="card-description">${business.description || 'No description added yet.'}</div>
        <div class="card-meta">${business.applyText || starterMessage}</div>
        <div class="card-actions">
          <button class="btn ghost waypoint-btn">Set GPS</button>
        </div>
      </div>
    `;

    card.querySelector('.waypoint-btn').addEventListener('click', () => post('setWaypoint', { id: business.id }));
    businessGrid.appendChild(card);
  });
}

function renderEditorList() {
  editorList.innerHTML = '';

  businesses.forEach((business) => {
    const row = document.createElement('div');
    row.className = `editor-item ${selectedEditorId === business.id ? 'active' : ''}`;
    row.innerHTML = `
      <strong>${business.label}</strong>
      <div>${business.category || 'Other'} â€¢ ${business.location || 'Unknown'}</div>
      <div class="helper">Owner: ${business.owner || 'Unassigned'}</div>
    `;

    row.addEventListener('click', () => loadEditorBusiness(business.id));
    editorList.appendChild(row);
  });
}

function resetEditor() {
  selectedEditorId = null;
  editorTitle.textContent = 'New Business';
  fieldId.value = '';
  fieldLabel.value = '';
  fieldCategory.value = categories[0] || 'Other';
  fieldStatus.value = 'Open';
  fieldOwner.value = '';
  fieldContact.value = '';
  fieldLocation.value = '';
  fieldHiring.checked = false;
  fieldImage.value = '';
  fieldX.value = '0.0';
  fieldY.value = '0.0';
  fieldZ.value = '0.0';
  fieldDescription.value = '';
  refreshPreview();
  renderEditorList();
}

function loadEditorBusiness(id) {
  const business = businesses.find((item) => item.id === id);
  if (!business) return;

  selectedEditorId = business.id;
  editorTitle.textContent = `Edit ${business.label}`;
  fieldId.value = business.id || '';
  fieldLabel.value = business.label || '';
  fieldCategory.value = business.category || categories[0] || 'Other';
  fieldStatus.value = business.status || 'Open';
  fieldOwner.value = business.owner || '';
  fieldContact.value = business.contact || '';
  fieldLocation.value = business.location || '';
  fieldHiring.checked = business.hiring === true;
  fieldImage.value = business.image || '';
  fieldX.value = business.coords?.x ?? 0.0;
  fieldY.value = business.coords?.y ?? 0.0;
  fieldZ.value = business.coords?.z ?? 0.0;
  fieldDescription.value = business.description || '';
  refreshPreview();
  renderEditorList();
}

function refreshPreview() {
  previewImage.src = fieldImage.value.trim() || defaultImage;
  previewLabel.textContent = fieldLabel.value.trim() || 'Business Preview';
  previewMeta.textContent = `${fieldOwner.value.trim() || 'Owner'} â€¢ ${fieldLocation.value.trim() || 'Location'}`;
}

function saveBusiness() {
  const payload = {
    id: fieldId.value.trim(),
    label: fieldLabel.value.trim(),
    category: fieldCategory.value,
    status: fieldStatus.value.trim(),
    owner: fieldOwner.value.trim(),
    contact: fieldContact.value.trim(),
    location: fieldLocation.value.trim(),
    hiring: fieldHiring.checked,
    image: fieldImage.value.trim(),
    coords: {
      x: Number(fieldX.value || 0),
      y: Number(fieldY.value || 0),
      z: Number(fieldZ.value || 0)
    },
    description: fieldDescription.value.trim(),
    applyText: starterMessage
  };

  post('saveBusiness', payload);
}

function deleteBusiness() {
  if (!selectedEditorId) return;
  post('deleteBusiness', { id: selectedEditorId });
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || !data.action) return;

  if (data.action === 'toggle') {
    setVisible(data.state === true);
    if (!data.state) {
      setMode('public');
    }
  }

  if (data.action === 'loadState') {
    businesses = Array.isArray(data.businesses) ? data.businesses : [];
    isAdmin = data.isAdmin === true;
    categories = Array.isArray(data.categories) ? data.categories : [];
    defaultImage = data.defaultImage || '';
    starterMessage = data.starterMessage || starterMessage;
    adminPermissions = Array.isArray(data.adminPermissions) ? data.adminPermissions : adminPermissions;
    populateCategories();
    filterBusinesses();
    resetEditor();
    setMode(data.mode === 'admin' && isAdmin ? 'admin' : 'public');
  }

  if (data.action === 'syncBusinesses') {
    businesses = Array.isArray(data.businesses) ? data.businesses : [];
    filterBusinesses();
    renderEditorList();

    if (selectedEditorId && businesses.some((item) => item.id === selectedEditorId)) {
      loadEditorBusiness(selectedEditorId);
    } else if (selectedEditorId) {
      resetEditor();
    }
  }
});

[searchInput, categoryFilter, hiringOnly].forEach((element) => {
  element.addEventListener('input', filterBusinesses);
  element.addEventListener('change', filterBusinesses);
});

[fieldLabel, fieldOwner, fieldLocation, fieldImage].forEach((element) => {
  element.addEventListener('input', refreshPreview);
});

closeBtn.addEventListener('click', () => post('close'));
switchToAdminBtn.addEventListener('click', () => setMode('admin'));
switchToPublicBtn.addEventListener('click', () => setMode('public'));
newBusinessBtn.addEventListener('click', resetEditor);
saveBusinessBtn.addEventListener('click', saveBusiness);
deleteBusinessBtn.addEventListener('click', deleteBusiness);
backToPublicBtn.addEventListener('click', () => setMode('public'));

document.addEventListener('keydown', (event) => {
  if (event.key === 'Escape') {
    post('close');
  }
});
