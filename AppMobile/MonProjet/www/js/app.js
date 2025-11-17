console.log("Script chargé, en attente de deviceready...");

function startScan() {
    console.log("Démarrage du scan Bluetooth...");
    document.getElementById("log").innerHTML = "Scanning for devices...";

    bluetoothle.startScan(function (result) {
        if (result.status === "scanResult") {
            console.log("📡 Appareil trouvé :", result);
            let logText = document.getElementById("log").innerHTML;

            // Ajouter l'appareil trouvé à l'affichage
            document.getElementById("log").innerHTML = logText + "<br>📡 " + result.name + " (RSSI: " + result.rssi + " dBm)";

        } else if (result.status === "scanStarted") {
            console.log("✅ Scan commencé...");
        }
    }, function (error) {
        console.error("⚠️ Erreur de scan :", error);
        alert("Erreur de scan : " + JSON.stringify(error));
    }, {
        services: [],  // Scanner tous les appareils BLE
        allowDuplicates: false
    });

    // Arrêter le scan après 5 secondes
    setTimeout(function () {
        bluetoothle.stopScan(function () {
            console.log("⏹️ Scan terminé.");
            alert("Scan terminé.");
        }, function (error) {
            console.error("⚠️ Erreur lors de l'arrêt du scan :", error);
        });
    }, 5000);
}

document.addEventListener('deviceready', function () {
    console.log("Device is ready!");

    // Vérifier si le Bluetooth est activé
    bluetoothle.initialize(function (status) {
        console.log("Bluetooth initialized:", status);

        if (status.status === "enabled") {
            //startScan();
        } else {
            alert("Le Bluetooth est désactivé. Activez-le pour scanner les appareils.");
        }
    }, {
        request: true, // Demande l'autorisation Bluetooth si nécessaire
        statusReceiver: true
    });
});

