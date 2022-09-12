//
//  photoSudokuViewController.swift
//  Sudoku
//
//  Created by 이주화 on 2022/09/06.
//

import UIKit
import AVFoundation

final class photoSudokuViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var refinedView: UIImageView!
    
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        preparedSession()
        session?.startRunning()
        
    }
    
    func preparedSession() {
        let camera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back)
        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera!)

            session = AVCaptureSession()
            session?.sessionPreset = AVCaptureSession.Preset.hd1280x720
            //해상도 지정
            session?.addInput(cameraInput)
            
            let videoOutput = AVCaptureVideoDataOutput()
            /*
             https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutput
             */
            
            //픽셀버퍼 핸들링을 용이하게 하기위해 BGRA타입으로 변환
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
            
            let sessionQueue = DispatchQueue(label: "camera")
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            session?.addOutput(videoOutput)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: session!)
            
            previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            previewLayer?.frame = cameraView.frame
            cameraView.layer.addSublayer(previewLayer!)
        } catch {
            
        }
        
    }
    
    
    // 비디오 프레임이 들어올 때마다 갱신됨
    /*
     참고
     https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutputsamplebufferdelegate/1385775-captureoutput
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput buffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        /*
         https://developer.apple.com/documentation/coremedia/1489236-cmsamplebuffergetimagebuffer
         */
        //CMSampleBuffer를 CVImageBuffer로 변환시켜준다.
        let CVimageBuffer = CMSampleBufferGetImageBuffer(buffer)!
        
        /*
         CVPixelBufferLockBaseAddress:
         https://developer.apple.com/documentation/corevideo/1457128-cvpixelbufferlockbaseaddress
         픽셀의 주소를 고정시켜준다.
         */
        CVPixelBufferLockBaseAddress(CVimageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        //이미지의 넓이 구하기
        let width = CVPixelBufferGetWidth(CVimageBuffer)
        let height = CVPixelBufferGetHeight(CVimageBuffer)
        
        //이미지에서 사용되는 각각의 Component가 사용하는 비트 수 선언
        let bitsPerComponent = 8
        
        //이미지의 row에 있는 바이트를 구한다.
        let bytesRow = CVPixelBufferGetBytesPerRow(CVimageBuffer)
        
        //이미지의 주소값을 구한다.
        let imageAddress = CVPixelBufferGetBaseAddress(CVimageBuffer)!
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        //비트 연산자 or 을 이용해 비트를 정리한다.
        let bitmap = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let context = CGContext(data: imageAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesRow, space:  colorSpace, bitmapInfo: bitmap)
        if let newContext = context {
            let frame = newContext.makeImage()
            DispatchQueue.main.async {
                let img = UIImage(cgImage: frame!)
                // crop
                let w = img.size.width
                let r = CGRect(x: 0, y: 0, width: w, height: w)
                let imgCrop = img.cgImage?.cropping(to: r)
                let refinedImage = UIImage(cgImage: imgCrop!)
                
                self.toRefinedView(refinedImage)
            }
        }
        //사용했던 픽셀 주소의 고정을 풀고 재사용이 가능하도록 한다.
        CVPixelBufferUnlockBaseAddress(CVimageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
    }

    func toRefinedView(_ capturedImage: UIImage) {
        refinedView.image = capturedImage
    }

    /*
     https://stijnoomes.com/access-camera-pixels-with-av-foundation/
     참고
    */

}
