import SwiftUI
import CoreBluetooth
import Foundation
import UIKit
import AVFoundation
import UserNotifications


struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()

    var body: some View {
        TabView {
            BLEScanView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label("Réception", systemImage: "antenna.radiowaves.left.and.right")
                }
            BLEImagesView(bluetoothManager: bluetoothManager)
                .tabItem {
                    Label("Affichage", systemImage: "rectangle.inset.filled.and.person.filled")
                }
        }
    }
}

// MARK: - Vue pour Scanner les périphériques BLE (Réception)
struct BLEScanView: View {
    @ObservedObject var bluetoothManager: BluetoothManager

    var body: some View {
        NavigationView {
            VStack {
                List(bluetoothManager.peripherals, id: \.0.identifier) { peripheral in
                    Button(action: {
                        bluetoothManager.selectedPeripheral = peripheral
                        bluetoothManager.logPeripheralInfo(peripheral)
                    }) {
                        VStack(alignment: .leading) {
                            Text("Nom: \(peripheral.2)")
                                .font(.headline)
                            Text("UUID: \(peripheral.0.identifier.uuidString)")
                                .font(.subheadline)
                            Text("RSSI: \(peripheral.3) dBm")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    }
                }

                if let selectedPeripheral = bluetoothManager.selectedPeripheral {
                    VStack(alignment: .leading) {
                        Text("Détails de \(selectedPeripheral.2)")
                            .font(.headline)
                            .padding()
                        Text("UUID: \(selectedPeripheral.0.identifier.uuidString)")
                            .font(.subheadline)
                        Text("RSSI: \(selectedPeripheral.3) dBm")
                            .font(.subheadline)
                        Text("Manufacturer Data: \(selectedPeripheral.1)")
                            .font(.subheadline)
                        Text("Service Data: \(selectedPeripheral.5)")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .navigationBarTitle("Scan des périphériques BLE")
        }
    }
}

struct BLEImagesView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    if let imageData = bluetoothManager.Messages[2].hexToData(),
                       let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width,
                                   height: geometry.size.height)
                            .background(Color.black)
                            .ignoresSafeArea()
                    } else {
                        Text("Aucune image")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationViewStyle(.stack) // Évite les bugs de layout en paysage
        }
    }
}


// MARK: - Bluetooth Manager (Scan + Broadcast)
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate {
    
    // Gestion du scan (central)
    @Published var peripherals: [(CBPeripheral, String, String, Int, [String: Any], String)] = []
    @Published var selectedPeripheral: (CBPeripheral, String, String, Int, [String: Any], String)?
    
    //pour les tests de graphs Y ou N
    var test = "N"
    var logName = "reception_500x10_suc_0,5ms_sur.csv"
    
    // Gestion de la diffusion (peripheral)
    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?

    override init() {
            super.init()
            
            // Initialisation avec identifiant de restauration
            centralManager = CBCentralManager(
                delegate: self,
                queue: nil,
                options: [CBCentralManagerOptionRestoreIdentifierKey: Bundle.main.bundleIdentifier! + ".ble.central"]
            )
        
            requestNotificationPermission()
            
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
            
            // Observers pour détecter premier plan / arrière-plan
            NotificationCenter.default.addObserver(self, selector: #selector(handleAppStateChange),
                                                   name: UIApplication.didEnterBackgroundNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(handleAppStateChange),
                                                   name: UIApplication.willEnterForegroundNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(handleAppStateChange),
                                                   name: UIApplication.didBecomeActiveNotification, object: nil)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.centralManager?.state == .poweredOn {
                    self.startScan(source: "init")
                }
            }
            clearAllCSVFiles()
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    
    func clearAllCSVFiles() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)

            let csvFiles = fileURLs.filter { $0.pathExtension.lowercased() == "csv" }

            for fileURL in csvFiles {
                try fileManager.removeItem(at: fileURL)
                print("🗑️ Supprimé : \(fileURL.lastPathComponent)")
            }

            if csvFiles.isEmpty {
                print("📂 Aucun fichier CSV à supprimer.")
            }

        } catch {
            print("❌ Erreur lors de la suppression des CSV : \(error)")
        }
    }


    // 🔍 Démarrer le scan BLE
    func startScan(source: String = "inconnu") {
        guard let centralManager = centralManager else { return }

        if centralManager.state != .poweredOn {
            print("⚠️ Bluetooth non activé. Scan ignoré. [source: \(source)]")
            return
        }

        centralManager.stopScan()
        print("🛑 Scan BLE stoppé (source: \(source))")

        let isInBackground = UIApplication.shared.applicationState != .active
        print(isInBackground)
        if isInBackground {
            print("🔍 Scan BLE mode background depuis : \(source)")
            switchToBackgroundScan()
        } else {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                try AVAudioSession.sharedInstance().setActive(true)
                print("🔊 Session audio activée")
            } catch {
                print("❌ Erreur session audio : \(error)")
            }
            print("🔍 Scan BLE mode foreground depuis : \(source)")
            switchToForegroundScan()
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("✅ Autorisation notifications locale accordée")
            } else {
                print("❌ Refus ou erreur : \(error?.localizedDescription ?? "inconnu")")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("🧠 iOS a restauré la session BLE avec : \(dict)")

        // Re-démarre un scan si nécessaire
        self.startScan(source: "willRestoreState")

    }
    
    func switchToForegroundScan() {
        centralManager?.stopScan()
        print("🔍 Scan général (tous périphériques)")
        centralManager?.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
    }

    func switchToBackgroundScan() {
        centralManager?.stopScan()
        let uuid = CBUUID(string: "180D")
        print("🔍 Scan filtré (service UUID : \(uuid))")
        centralManager?.scanForPeripherals(withServices: [uuid], options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
        print("🎯 [CHECK] centralManager isScanning: \(centralManager?.isScanning ?? false)")

    }

    @objc private func handleAppStateChange(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didEnterBackgroundNotification:
            print("⬇️ App passe en background")
            startScan(source: "didEnterBackground")
            startBackgroundScanLoop()

        case UIApplication.willEnterForegroundNotification:
            print("⬆️ App revient en foreground (préparation)")

        case UIApplication.didBecomeActiveNotification:
            print("🟢 App devient active → scan général")
            stopBackgroundScanLoop()
            startScan(source: "didBecomeActive")
            
        default:
            break
        }
    }
    
    var backgroundScanTimer: Timer?

    func startBackgroundScanLoop() {
        // Annule un timer existant s’il y en a un
        backgroundScanTimer?.invalidate()

        // Crée un timer qui relance startScan toutes les 30 sec
        backgroundScanTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            print("🔁 Timer BG → relance du scan BLE")
            self.startScan(source: "TimerBG")
        }

        // Important : ajoute-le au runloop en mode .common
        RunLoop.main.add(backgroundScanTimer!, forMode: .common)
    }

    func stopBackgroundScanLoop() {
        backgroundScanTimer?.invalidate()
        backgroundScanTimer = nil
    }

    
    func logPeripheralInfo(_ peripheral: (CBPeripheral, String, String, Int, [String: Any], String)) {
        print("Infos détaillées du périphérique sélectionné:")
        print("Nom: \(peripheral.2)")
        print("UUID: \(peripheral.0.identifier.uuidString)")
        print("RSSI: \(peripheral.3) dBm")
        print("Manufacturer Data: \(peripheral.1)")  // Données brutes en hexadécimal
        print("Service Data: \(peripheral.5)")  // Données brutes en hexadécimal
    }

    // MARK: - Gestion de l'état Bluetooth
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("✅ Bluetooth activé.")
            self.startScan(source: "didUpdateState")
        case .poweredOff:
            print("❌ Bluetooth désactivé.")
        default:
            print("⚠️ État Bluetooth : \(central.state.rawValue)")
        }
    }

    
    // Dictionnaire pour stocker l’historique des Manufacturer Data et leur nombre d’occurrences
    var receivedManufacturerData: [Int: [String: Int]] = [0: [:],1: [:],2: [:],3: [:]]
    
    var lastReceivedManufacturerData: [Int: [String: Int]] = [0: [:],1: [:],2: [:],3: [:]]
    
    //0->texte 1->audio 2->image 3->message important
    @Published var Messages = ["","","",""]
    
    var lastCompleteMessages = ["","","",""]
    
    var octNumber = 2
    
    let audioManager = AudioPlaybackManager()
    
    private let dataAccessQueue = DispatchQueue(label: "com.monapp.ble.receivedDataQueue")
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi: NSNumber) {
        /*if let advertisedUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            print("📡 [BG TEST] Service UUIDs dans pub : \(advertisedUUIDs)")
        }*/
        
        
        // Extraction du Manufacturer Data (Manufacturer Specific Data)
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data ?? Data()
        let manufacturerDataHex = manufacturerData.hexString()
    

        // Vérification que le Manufacturer Data contient au moins 2 octets pour le sigle
        guard manufacturerDataHex.count >= 4 else {
            return
        }

        // Extraction des 2 premiers octets du Manufacturer Data (sigle de l'entreprise)
        let sigIndex = manufacturerDataHex.index(manufacturerDataHex.startIndex, offsetBy: 4)
        let SIG_ENTREPRISE = manufacturerDataHex[..<sigIndex] // Récupérer les 2 premiers octets
        let SIG = String(SIG_ENTREPRISE.suffix(2) + SIG_ENTREPRISE.prefix(2))
        //print("sig : \(SIG)")

        if (SIG == "1245") && (manufacturerDataHex.count >= 6+4*self.octNumber) {

            let type = self.typeOfMessage(dataHexString: manufacturerDataHex)
            //print(type)
            
            if test == "N"{
                if self.isSameMessage(AllData: lastReceivedManufacturerData, Type: type, dataHexString: manufacturerDataHex) == false {
                    return
                }
                
                let (condition, max) = self.isMessageComplete(AllData: receivedManufacturerData, Type: type)
                if condition {
                    let message = self.constituteMessage(AllData: self.receivedManufacturerData, Max: max, Type: type)
                    
                    if self.lastCompleteMessages[type] == message {
                        //print("Message déjà traité. Ignoré.")
                        return
                    }
                    self.lastCompleteMessages[type] = message
                    self.lastReceivedManufacturerData[type] = self.receivedManufacturerData[type]
                    self.receivedManufacturerData[type] = [:]
                    print("Message complet reçu")
                    
                    DispatchQueue.main.async {
                        self.Messages[type] = message
                        
                        if type == 1 {
                            self.audioManager.enqueueAudio(data: message.hexToData()!, fileExtension: "aac")
                        } else if type == 3 {
                            if let ascii = message.hexToASCII() {
                                self.sendNotification(title: "LeoBlue", body: ascii)
                            }
                        }
                    }
                    
                    return
                }
                
                
                // à enlever pour les tests google sheet
                if self.receivedManufacturerData[type]!.keys.contains(manufacturerDataHex) {
                    //print("no add : \(manufacturerDataHex)")
                    return
                }
            }
            
            let rssiValue = rssi.intValue
            let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? peripheral.name ?? "Inconnu"
            
            dataAccessQueue.async {
                if var existingDataMap = self.receivedManufacturerData[type] {
                    if let count = existingDataMap[manufacturerDataHex] {
                        existingDataMap[manufacturerDataHex] = count + 1
                    } else {
                        existingDataMap[manufacturerDataHex] = 1
                    }
                    self.receivedManufacturerData[type] = existingDataMap
                } else {
                    self.receivedManufacturerData[type] = [manufacturerDataHex: 1]
                }

                // Optionnel : log en debug
                //print("📊 Historique des Manufacturer Data pour \(name): \(self.receivedManufacturerData)")
                if self.test == "Y" {
                    let (num, max) = self.numTrame(dataHex: manufacturerDataHex)
                    self.appendToCSV(data: [String(num ?? 0), String(max ?? 0)])
                }
            }

            DispatchQueue.main.async {
                // Mise à jour dans la liste des périphériques
                if let index = self.peripherals.firstIndex(where: { $0.0.identifier == peripheral.identifier }) {
                    self.peripherals[index] = (peripheral, manufacturerDataHex, name, rssiValue, advertisementData, "")
                } else {
                    self.peripherals.append((peripheral, manufacturerDataHex, name, rssiValue, advertisementData, ""))
                }
            }
        }
    }
    
    func currentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
    
    func appendToCSV(data: [String]) {
        let timestamp = currentTimestamp()
        
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(logName)

        let line = ([timestamp] + data).joined(separator: ",")

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                if let data = ("\n" + line).data(using: .utf8) {
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                let header = ["Timestamp"] + data.indices.map { "Col\($0 + 1)" }
                let fullContent = ([header.joined(separator: ","), line]).joined(separator: "\n")
                try fullContent.write(to: fileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("❌ Erreur CSV : \(error)")
        }
    }
    
    func numTrame(dataHex: String) -> (Int?,Int?){
        let startNum = dataHex.index(dataHex.startIndex, offsetBy: 6)
        let endNum = dataHex.index(dataHex.startIndex, offsetBy: 6+2*self.octNumber)
        
        let num = Int(dataHex[startNum..<endNum], radix: 16)
        
        let startMax = dataHex.index(dataHex.startIndex, offsetBy: 6+2*self.octNumber)
        let endMax = dataHex.index(dataHex.startIndex, offsetBy: 6+4*self.octNumber)
        
        let Max = Int(dataHex[startMax..<endMax], radix: 16)
        
        return (num,Max)
    }
    
    func typeOfMessage(dataHexString: String) -> Int {
        // Extraction des indices pour récupérer les deux octets du type
        let startType = dataHexString.index(dataHexString.startIndex, offsetBy: 4)
        let endType = dataHexString.index(dataHexString.startIndex, offsetBy: 6)
        
        // Conversion des octets en entier (en base 16)
        if let type = Int(dataHexString[startType..<endType], radix: 16) {
            // Utilisation de switch pour retourner 1, 2 ou 3 en fonction de type
            switch type {
            case 0:
                return 0
            case 15:
                return 1
            case 240:
                return 2
            case 255:
                return 3
            default:
                return -1  // Si la valeur de type n'est pas 0, 15 ou 240
            }
        }
        return -1  // Si la conversion échoue
    }

    func isSameMessage(AllData: [Int?: [String: Int]], Type: Int?, dataHexString: String) -> Bool {
        guard let type = Type, let messages = AllData[type] else {
            return false
        }
        for (dataHex, _) in messages {
            if dataHex == dataHexString {
                return false
            }
        }
        return true
    }
    
    func isMessageComplete(AllData: [Int?: [String: Int]], Type: Int?) -> (Bool, Int?){
        if let (dataHex, _) = AllData[Type]?.first{
            let startMax = dataHex.index(dataHex.startIndex, offsetBy: 6+2*self.octNumber)
            let endMax = dataHex.index(dataHex.startIndex, offsetBy: 6+4*self.octNumber)
            
            let Max = Int(dataHex[startMax..<endMax], radix: 16)
            
            if AllData[Type]?.count == Max {
                return (true, Max)
            }else{
                return (false, 0)
            }
        }else{
            return (false, 0)
        }
    }
    
    func constituteMessage(AllData: [Int: [String: Int]], Max: Int?, Type: Int?) -> String {
        var data: [(Int, String)] = []

        guard let type = Type, let messages = AllData[type] else {
            return ""
        }

        for (dataHex, _) in messages {
            guard dataHex.count >= 6 + 4 * self.octNumber else {
                continue  // trame trop courte, on ignore
            }

            let startCount = dataHex.index(dataHex.startIndex, offsetBy: 6)
            let endCount = dataHex.index(dataHex.startIndex, offsetBy: 6 + 2 * self.octNumber)
            let countString = dataHex[startCount..<endCount]
            
            guard let count = Int(countString, radix: 16) else {
                continue  // si la conversion échoue, on ignore
            }

            let endMax = dataHex.index(dataHex.startIndex, offsetBy: 6 + 4 * self.octNumber)
            let partMessage = String(dataHex[endMax...])

            data.append((count, partMessage))
        }

        let sortedData = data.sorted { $0.0 < $1.0 }
        let message = sortedData.map { $0.1 }.joined()

        return message
    }
    
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // immédiat
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Erreur d’envoi de notification : \(error)")
            } else {
                print("🔔 Notification envoyée : \(title) – \(body)")
            }
        }
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            print("✅ Prêt à diffuser.")
        } else {
            print("⚠️ Bluetooth désactivé ou indisponible.")
        }
    }
}

// MARK: - Class pour lecture audio
class AudioPlaybackManager: NSObject {
    private let player = AVQueuePlayer()
    private var audioQueue: [(Data, String)] = []
    private var isPreparingItem = false
    private var isObserving = false
    private var currentlyPlayingURL: URL?

    override init() {
        super.init()

        observePlayerEnd() // si tu l'as déjà
        player.addObserver(
            self,
            forKeyPath: "timeControlStatus",
            options: [.new, .old],
            context: nil
        )
    }


    func enqueueAudio(data: Data, fileExtension: String = "m4a") {
        audioQueue.append((data, fileExtension))
        
        // Si le player est vide, on prépare immédiatement les 2 premiers morceaux
        if player.items().isEmpty {
            prepareNextIfNeeded()
            prepareNextIfNeeded()
            player.play()
        } else {
            // Sinon on en prépare un de plus en avance
            prepareNextIfNeeded()
        }
    }

    private func prepareNextIfNeeded() {
        guard !isPreparingItem, !audioQueue.isEmpty else { return }

        isPreparingItem = true
        let (data, fileExtension) = audioQueue.removeFirst()

        let filename = "chunk_\(UUID().uuidString).\(fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: tempURL)

            self.currentlyPlayingURL = tempURL
            let item = AVPlayerItem(url: tempURL)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(itemDidFinishPlaying(_:)),
                name: .AVPlayerItemDidPlayToEndTime,
                object: item
            )

            player.insert(item, after: nil)

            print("🎧 Item ajouté à la file : \(fileExtension)")

        } catch {
            print("❌ Erreur fichier audio : \(error)")
        }

        isPreparingItem = false
        prepareNextIfNeeded()
    }

    private func observePlayerEnd() {
        guard !isObserving else { return }
        isObserving = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleQueueEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }

    @objc private func handleQueueEnd(notification: Notification) {
        print("✅ Fin de lecture d’un item")

        // 🗑️ Supprimer l’ancien fichier
        if let url = currentlyPlayingURL {
            try? FileManager.default.removeItem(at: url)
            print("🗑️ Fichier supprimé : \(url.lastPathComponent)")
            currentlyPlayingURL = nil
        }

        // Relancer la lecture si besoin
        if player.timeControlStatus != .playing && !player.items().isEmpty {
            print("▶️ Reprise de la lecture")
            player.play()
        }

        prepareNextIfNeeded()
    }


    @objc private func itemDidFinishPlaying(_ notification: Notification) {
        // Optionnel : nettoyage ou logs
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "timeControlStatus" {
            switch player.timeControlStatus {
            case .playing:
                print("🎬 Lecture en cours")
            case .paused:
                print("⏸ Lecture en pause")
            case .waitingToPlayAtSpecifiedRate:
                print("⏳ Attente du buffer")
            @unknown default:
                print("❓ État inconnu")
            }
        }
    }

    deinit {
        player.removeObserver(self, forKeyPath: "timeControlStatus")
    }
}


// MARK: - Extension pour convertir Data en Hexadécimal
extension Data {
    func hexString() -> String {
        return self.map { String(format: "%02X", $0) }.joined(separator: "")
    }
}

// MARK: - Extension pour convertir un hex en Data
extension String {
    func hexToData() -> Data? {
        var hex = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // Supprime "0x" si présent
        if hex.hasPrefix("0X") {
            hex.removeFirst(2)
        }

        // Vérifie que la longueur est paire
        guard hex.count % 2 == 0 else { return nil }

        // Conversion en Data
        var data = Data(capacity: hex.count / 2)
        for index in stride(from: 0, to: hex.count, by: 2) {
            let start = hex.index(hex.startIndex, offsetBy: index)
            let end = hex.index(start, offsetBy: 2)
            let byteString = String(hex[start..<end])
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
        }

        return data
    }
}

// MARK: - Extension pour convertir un hex en ascii
extension String {
    func hexToASCII() -> String? {
        var asciiString = ""
        var index = self.startIndex

        while index < self.endIndex {
            let nextIndex = self.index(index, offsetBy: 2)
            guard nextIndex <= self.endIndex else { break }

            let hexByte = self[index..<nextIndex]
            guard let byte = UInt8(hexByte, radix: 16) else { return nil }

            // Directement ici : UnicodeScalar(byte) n’est pas optionnel
            let scalar = UnicodeScalar(byte)
            asciiString.append(Character(scalar))

            index = nextIndex
        }

        return asciiString
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
