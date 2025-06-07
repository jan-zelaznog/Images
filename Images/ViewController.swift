//
//  ViewController.swift
//  Images
//
//  Created by Ángel González on 06/06/25.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate, AVCaptureMetadataOutputObjectsDelegate, AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let err = error {
            print ("error en la grabación de video \(err.localizedDescription)")
        }
    }
    
    var btn = UIButton(type: .custom)
    var iv = UIImageView()
    let ipc = UIImagePickerController()
    var scan = UIButton(type: .custom)
    var vSesion: AVCaptureSession!
    var videoLayer: AVCaptureVideoPreviewLayer!
    var rec = UIButton(type: .custom)
    var grabando = false
    var archivoGrabacion: AVCaptureMovieFileOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(iv)
        self.view.addSubview(btn)
        self.view.addSubview(scan)
        self.view.addSubview(rec)
        
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.backgroundColor = .gray
        iv.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        iv.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -180).isActive = true
        iv.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30).isActive = true
        iv.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30).isActive = true
        iv.contentMode = .scaleAspectFit
        //iv.widthAnchor.constraint(equalToConstant:150).isActive = true
        //iv.heightAnchor.constraint(equalToConstant:150).isActive = true
        //iv.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant:150).isActive = true
        btn.heightAnchor.constraint(equalToConstant:45).isActive = true
        btn.centerXAnchor.constraint(equalTo:view.centerXAnchor).isActive = true
        btn.topAnchor.constraint(equalTo:iv.bottomAnchor, constant: 10).isActive = true
        
        btn.setImage(UIImage(systemName:"camera.fill"), for: .normal)
        btn.addTarget(self, action:#selector(btnTouch), for: .touchUpInside)
        
        scan.translatesAutoresizingMaskIntoConstraints = false
        scan.widthAnchor.constraint(equalToConstant:150).isActive = true
        scan.heightAnchor.constraint(equalToConstant:45).isActive = true
        scan.centerXAnchor.constraint(equalTo:view.centerXAnchor).isActive = true
        scan.topAnchor.constraint(equalTo:btn.bottomAnchor, constant: 10).isActive = true
        
        scan.setImage(UIImage(systemName:"scanner.fill"), for: .normal)
        scan.addTarget(self, action:#selector(btnScanTouch), for: .touchUpInside)
        
        rec.translatesAutoresizingMaskIntoConstraints = false
        rec.widthAnchor.constraint(equalToConstant:150).isActive = true
        rec.heightAnchor.constraint(equalToConstant:45).isActive = true
        rec.centerXAnchor.constraint(equalTo:view.centerXAnchor).isActive = true
        rec.topAnchor.constraint(equalTo:scan.bottomAnchor, constant: 10).isActive = true
        
        rec.setImage(UIImage(systemName:"video.fill"), for: .normal)
        rec.addTarget(self, action:#selector(btnRecTouch), for: .touchUpInside)
    }

    @objc
    func btnScanTouch(){
        // instanciamos el objeto sesion de captura
        vSesion = AVCaptureSession()
        // conectamos el dispositivo de video y ponemos el preview layer
        configuraVideo()
        vSesion.startRunning()
        // Para detectar códigos:
        let metadatos = AVCaptureMetadataOutput()
        if vSesion.canAddOutput(metadatos) {
            vSesion.addOutput(metadatos)
            metadatos.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadatos.metadataObjectTypes = [.qr, .ean13, .dataMatrix]
        }
    }
    
    @objc
    func btnRecTouch(){
        if !grabando {
            // instanciamos el objeto sesion de captura
            vSesion = AVCaptureSession()
            vSesion.beginConfiguration()
            // conectamos el dispositivo de video y ponemos el preview layer
            configuraVideo()
            guard let aDispositivo = AVCaptureDevice.default(for: .audio) else { return }
            do {
                // si hay un dispositivo de captura de audio, entonces intentamos agregarlo a la sesión
                let entradaAudio = try AVCaptureDeviceInput(device: aDispositivo)
                if vSesion.canAddInput(entradaAudio) {
                    vSesion.addInput(entradaAudio)
                }
                rec.setImage(UIImage(systemName:"stop.circle.fill"), for: .normal)
                
                grabando = true
                // 1. Encontrar la ruta a la carpeta documents
                if var dURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let df = DateFormatter()
                    df.locale = Locale(identifier:"es_MX")
                    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let tms = df.string(from: Date())
                    // 2. Asignar un nombre a la foto y agregarlo a la ruta
                    dURL.appendPathComponent("\(tms).mov")
                    archivoGrabacion = AVCaptureMovieFileOutput()
                    if vSesion.canAddOutput(archivoGrabacion) {
                        vSesion.addOutput(archivoGrabacion)
                    }
                    vSesion.commitConfiguration()
                    vSesion.startRunning()
                    archivoGrabacion.startRecording(to: dURL, recordingDelegate: self)
                }
                
            }
            catch {
                return
            }
        }
        else {
            vSesion.stopRunning()
            videoLayer.removeFromSuperlayer()
            rec.setImage(UIImage(systemName:"video.fill"), for: .normal)
            grabando = false
            archivoGrabacion.stopRecording()
        }
    }
    
    func configuraVideo() {
        // comprobamos si el telefono tiene un dispositivo de captura de video
        guard let vDispositivo = AVCaptureDevice.default(for: .video) else { return }
        do {
            // si hay un dispositivo de captura de video, entonces intentamos agregarlo a la sesión
            let entradaVideo = try AVCaptureDeviceInput(device: vDispositivo)
            if vSesion.canAddInput(entradaVideo) {
                vSesion.addInput(entradaVideo)
            }
            // agregamos un layer para mostrar lo que esta "viendo" la cámara
            videoLayer = AVCaptureVideoPreviewLayer(session: vSesion)
            videoLayer.frame = self.view.bounds.insetBy(dx: 0, dy:60)
            self.view.layer.addSublayer(videoLayer)
        }
        catch {
            return
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // identificamos si hay un objeto
        if let objetoLeido = metadataObjects.first {
            // emitir un sonido para avisar al usuario que ya se encontró un código
            AudioServicesPlaySystemSound(1057)
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            // obtenemos el valor (el contenido) del objeto
            guard let codigoLeido = objetoLeido as? AVMetadataMachineReadableCodeObject
            else { return }
            guard let cadena = codigoLeido.stringValue
            else { return }
            // HACER ALGO CON EL CODIGO ENCONTRADO
            print ("encontré el código \(cadena)")
            vSesion.stopRunning()
            videoLayer.removeFromSuperlayer()
        }
    }
    
    @objc
    func btnTouch(){
        ipc.delegate = self
        ipc.allowsEditing = true
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let ac = UIAlertController(title: "hola", message:"Elige el origen de la imagen", preferredStyle: .alert)
            let action = UIAlertAction(title: "Galería", style: .default) {
                alertaction in
                self.ipc.sourceType = .photoLibrary
                Timer.scheduledTimer(withTimeInterval:0.1, repeats:false) { t in
                    self.present(self.ipc, animated: true)
                }
            }
            let action2 = UIAlertAction(title: "Cámara", style: .default) {
                alertaction in
                self.ipc.sourceType = .camera
                self.checarPermisos()
            }
            ac.addAction(action)
            ac.addAction(action2)
            self.present(ac, animated: true)
        }
        else {
            ipc.sourceType = .photoLibrary
            self.present(ipc, animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let img = info[.editedImage] as? UIImage {
            iv.image = img
            // para guardar la imagen tomada a la galería
            // UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
            // guardarla a docs
            guardaEnDocs (img)
        }
        picker.dismiss(animated: true)
    }
    
    func checarPermisos () {
        let estado = AVCaptureDevice.authorizationStatus(for: .video)
        switch (estado) {
            case .authorized:
            self.present (self.ipc, animated: true)
            case .denied,
                .restricted:
                self.solicitarPermisos()
            case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { auth in
                if auth {
                    DispatchQueue.main.async {
                        self.present (self.ipc, animated: true)
                    }
                }
            }
            default:
            print ("este estado de permisos es nuevo")
        }
    }
    
    func solicitarPermisos () {
        let ac = UIAlertController(title: "hola", message:"Puede autorizar el uso de la cámara desde la configuración del teléfono. ¿Desea hacerlo ahora?", preferredStyle: .alert)
        let action = UIAlertAction(title: "ok", style: .default) {
            alertaction in
            if let settingsURL = URL(string:UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
        let action2 = UIAlertAction(title: "ño", style: .destructive)
        ac.addAction(action)
        ac.addAction(action2)
        self.present(ac, animated: true)
    }
    
    func guardaEnDocs (_ laImagen:UIImage) {
        // 1. Encontrar la ruta a la carpeta documents
        if var dUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let df = DateFormatter()
            df.locale = Locale(identifier:"es_MX")
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let tms = df.string(from: Date())
            // 2. Asignar un nombre a la foto y agregarlo a la ruta
            dUrl.appendPathComponent("\(tms).jpg")
            // 3. obtener los bytes de la imagen, transformarlos al tipo de imagen adecuado
            let bytes = laImagen.jpegData(compressionQuality:0.5)
            do {
                // 4. guardar la foto
                try bytes?.write(to: dUrl, options: .atomic)
                print ("se guardó la foto en \(dUrl.path())")
            }
            catch {
                print ("error al guardar la foto")
            }
        }
    }
}

