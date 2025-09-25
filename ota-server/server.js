const express = require('express');
const multer = require('multer');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 8080;

// Configuration CORS
app.use(cors());
app.use(express.json());

// Configuration du stockage des firmwares
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = path.join(__dirname, 'firmwares');
    if (!fs.existsSync(uploadPath)) {
      fs.mkdirSync(uploadPath, { recursive: true });
    }
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const timestamp = Date.now();
    const version = req.body.version || 'unknown';
    cb(null, `firmware_v${version}_${timestamp}.bin`);
  }
});

const upload = multer({ storage });

// Base de données simple des versions (en production, utiliser une vraie DB)
let firmwareVersions = {
  'latest': {
    version: '1.0.0',
    filename: null,
    checksum: null,
    size: 0,
    releaseDate: new Date().toISOString(),
    changelog: 'Version initiale'
  }
};

// Middleware d'authentification
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: 'Token d\'authentification requis' });
  }
  
  // En production, vérifier le token JWT
  if (token !== process.env.OTA_AUTH_TOKEN) {
    return res.status(403).json({ error: 'Token invalide' });
  }
  
  next();
};

// Route de vérification des mises à jour
app.get('/api/check-update', (req, res) => {
  const { deviceId, currentVersion, macAddress } = req.query;
  
  if (!deviceId || !currentVersion) {
    return res.status(400).json({ error: 'deviceId et currentVersion requis' });
  }
  
  const latestVersion = firmwareVersions.latest;
  
  // Log de la vérification
  console.log(`Vérification OTA - Device: ${deviceId}, Version actuelle: ${currentVersion}, Dernière version: ${latestVersion.version}`);
  
  // Comparer les versions
  const hasUpdate = latestVersion.version !== currentVersion && latestVersion.filename;
  
  res.json({
    hasUpdate,
    latestVersion: latestVersion.version,
    downloadUrl: hasUpdate ? `/api/download/${latestVersion.filename}` : null,
    size: latestVersion.size,
    checksum: latestVersion.checksum,
    changelog: latestVersion.changelog,
    mandatory: false
  });
});

// Route de téléchargement du firmware
app.get('/api/download/:filename', (req, res) => {
  const filename = req.params.filename;
  const filePath = path.join(__dirname, 'firmwares', filename);
  
  if (!fs.existsSync(filePath)) {
    return res.status(404).json({ error: 'Firmware non trouvé' });
  }
  
  console.log(`Téléchargement du firmware: ${filename}`);
  
  res.setHeader('Content-Type', 'application/octet-stream');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
  
  const fileStream = fs.createReadStream(filePath);
  fileStream.pipe(res);
});

// Route d'upload de nouveau firmware (admin seulement)
app.post('/api/upload-firmware', authenticateToken, upload.single('firmware'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'Fichier firmware requis' });
  }
  
  const { version, changelog } = req.body;
  
  if (!version) {
    return res.status(400).json({ error: 'Version requise' });
  }
  
  // Calculer le checksum
  const fileBuffer = fs.readFileSync(req.file.path);
  const checksum = crypto.createHash('sha256').update(fileBuffer).digest('hex');
  
  // Mettre à jour la base de données des versions
  firmwareVersions.latest = {
    version,
    filename: req.file.filename,
    checksum,
    size: req.file.size,
    releaseDate: new Date().toISOString(),
    changelog: changelog || 'Mise à jour du firmware'
  };
  
  console.log(`Nouveau firmware uploadé: ${req.file.filename}, Version: ${version}`);
  
  res.json({
    success: true,
    version,
    filename: req.file.filename,
    checksum,
    size: req.file.size
  });
});

// Route de statistiques
app.get('/api/stats', authenticateToken, (req, res) => {
  const firmwaresPath = path.join(__dirname, 'firmwares');
  const files = fs.existsSync(firmwaresPath) ? fs.readdirSync(firmwaresPath) : [];
  
  res.json({
    totalFirmwares: files.length,
    latestVersion: firmwareVersions.latest.version,
    lastUpdate: firmwareVersions.latest.releaseDate,
    availableVersions: Object.keys(firmwareVersions)
  });
});

// Route de santé
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'Pet Smart Home OTA Server'
  });
});

// Gestion des erreurs
app.use((error, req, res, next) => {
  console.error('Erreur serveur:', error);
  res.status(500).json({ error: 'Erreur interne du serveur' });
});

// Démarrage du serveur
app.listen(PORT, () => {
  console.log(`🚀 Serveur OTA démarré sur le port ${PORT}`);
  console.log(`📡 Endpoint de vérification: http://localhost:${PORT}/api/check-update`);
  console.log(`📥 Endpoint de téléchargement: http://localhost:${PORT}/api/download`);
});

module.exports = app;