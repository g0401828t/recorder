//
//  ViewController.swift
//  talkyRecorder
//
//  Created by 정원석 on 2020/11/12.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {

    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var recordPauseButton: UIButton!
    @IBOutlet weak var stopRecordButton: UIButton!
    
    @IBOutlet weak var pvProgressPlay: UIProgressView!
    @IBOutlet weak var lbCurrentTime: UILabel!
    @IBOutlet weak var lbEndTime: UILabel!
    
    @IBOutlet weak var lbRecordTime: UILabel!
    
    @IBOutlet weak var uploadButton: UIButton!     // Popupview 일때 쓰려고 만듦
    @IBOutlet weak var dissmissButton: UIButton!   // Popupview 일때 쓰려고 만듦
    
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 80, weight: .black, scale: .large)
    let symbolConfig1 = UIImage.SymbolConfiguration(pointSize: 50, weight: .black, scale: .large)

    
    var recordCommand = "record"
    var stopCommand = "recordStop"
    var playCommand = "play"
    //asdfasdf
    
    //변수 및 상수
    var audioPlayer : AVAudioPlayer!    //avaudioplayer인스턴스 변수
    var audioFile : URL!                // 재생할 오디오의 파일명 변수
    let MAX_VOLUME : Float = 10.0       //최대 불륨, 실수형 상수
    var progressTimer : Timer!          //타이머를 위한 변수
    
    let timePlayerSelector:Selector = #selector(ViewController.updatePlayTime)
    let timeRecordSelector:Selector = #selector(ViewController.updateRecordTime)
    
    var audioRecorder : AVAudioRecorder!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //녹음모드일 때는 새 파일인 recordFile.m4a가 생성 된다.
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        //audioFile = documentDirectory.appendingPathComponent("recordFile.m4a")
        audioFile = documentDirectory.appendingPathComponent("recordFile.mp4")
        
        
        initRecord()
    }
    
    
    
    //녹음을 위한 초기화 함수 : 음질은 최대, 비트율 320kbps, 오디오 채널은 2, 샘플율은 44,100hz
    func initRecord() -> Void {
        
//        let recordSettings = [
//            AVFormatIDKey : NSNumber(value : kAudioFormatAppleLossless as UInt32),
//            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
//            AVEncoderBitRateKey : 320000,
//            AVNumberOfChannelsKey : 2,
//            AVSampleRateKey : 44100.0] as [String : Any]
        
        let recordSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 16000,
            AVSampleRateKey: 16000] as [String : Any]
        
        do {
            // selectAudioFile 함수에서 저장한 audioFile을 url로 하는 audioRecorder 인스턴스를 생성
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
        } catch let error as NSError {
            print("error-initRecord:\(error)")
        }
        audioRecorder.delegate = self
        //박자관련
        audioRecorder.isMeteringEnabled = true
        
        audioRecorder.prepareToRecord()
        
//        slVolume.value = 1.0
//        audioPlayer.volume = slVolume.value
        lbEndTime.text = convertNSTimeInterval2String(0)
        lbCurrentTime.text = convertNSTimeInterval2String(0)
////        버튼 모드 비활성화
//        setPlayButton(false, pause: false, stop: false)
        
        // 녹음 버튼 외 모든 버튼 비활성화
        playPauseButton.isEnabled = false
        stopRecordButton.isEnabled = false
        dissmissButton.isEnabled = false
        
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord)
        } catch let error as NSError {
            print("error-setcategory : \(error)")
        }
        
        do {
            try session.setActive(true)
        } catch let error as NSError {
            print("error-setActive : \(error)")
        }
        
    }
    
    func initPlay() -> Void{
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        } catch let error as NSError {
            print("Error-initPlay : \(error)")
        }
        
        audioPlayer.delegate = self // audioPlayer의 델리게이트는 self
        audioPlayer.prepareToPlay() // prepareToPlay() 실행
        audioPlayer.volume = MAX_VOLUME
        
        
        //프로그레스 뷰의 진행을 0으로 초기화
        pvProgressPlay.progress = 0
        //오디오 파일의 재생시간인 audioplayer.duration값을 이 함수를 이용해서 텍스트에 출력
        lbEndTime.text = convertNSTimeInterval2String(audioPlayer.duration)
        //lbcurrentTime텍스트에는 이 함수를 이용해서 00:00이 출력되도록 한다.
        lbCurrentTime.text = convertNSTimeInterval2String(0)
    }

    
    
    @IBAction func startPauseRecord(_ sender: Any) {
        stopCommand = "recording"
        print(recordCommand)
        
        stopRecordButton.isEnabled = true
        playPauseButton.isEnabled = false
        
        if recordCommand == "record"{
            recordPauseButton.setImage(UIImage(systemName: "record.circle", withConfiguration: symbolConfig), for: .normal)

            audioRecorder.record()
            progressTimer=Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timeRecordSelector, userInfo: nil, repeats: true)
            
            recordCommand = "pauseRecord"
            playCommand = "play"
            
        } else if recordCommand == "pauseRecord" {
            audioRecorder.pause()
            recordPauseButton.setImage(UIImage(systemName: "record.circle.fill", withConfiguration: symbolConfig), for: .normal)
            progressTimer.invalidate()
            recordCommand = "record"
        }
    }
    
    @IBAction func playPauseAudio(_ sender: Any) {
        stopCommand = "playing"
        print(playCommand)
        
        recordPauseButton.isEnabled = false
        
        initPlay()
        
        if playCommand == "play"{
            playPauseButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: symbolConfig1), for: .normal)
            audioPlayer.play()
            //프로그레스 타이머 설정
            progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
            playCommand = "pause"

        }else if playCommand == "pause"{
            playPauseButton.setImage(UIImage(systemName: "play.circle", withConfiguration: symbolConfig1), for: .normal)
            audioPlayer.pause()
            playCommand = "play"
        }
    }
    
    
    @IBAction func stopRecordAudio(_ sender: Any) {
        print(stopCommand)
        if stopCommand == "recording"{
            playPauseButton.isEnabled = true
            recordPauseButton.setImage(UIImage(systemName: "record.circle.fill", withConfiguration: symbolConfig), for: .normal)
            progressTimer.invalidate()
            lbCurrentTime.text = convertNSTimeInterval2String(0)
            audioRecorder.stop()
            
            recordCommand = "record"
            
            playPauseButton.isEnabled = true
        } else if stopCommand == "playing" {
            audioPlayer.stop()
            //오디오를 정지하고 재생하면 다시 처음부터 재생, 시간 초기화
            audioPlayer.currentTime = 0
            playCommand = "play"
            playPauseButton.setImage(UIImage(systemName: "play.circle", withConfiguration: symbolConfig1), for: .normal)
             
            recordPauseButton.isEnabled = true
        }
        
    }
    
    
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool){
        playCommand = "play"
        lbCurrentTime.text = convertNSTimeInterval2String(0)
        progressTimer.invalidate()
        recordPauseButton.isEnabled = true
        print("finished playing")
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        uploadButton.isEnabled = true
    }
    
    //00:00형태로 바꾸기 위해 timeinterval 값을 받아 문자열로 돌려보내는 함수
    func convertNSTimeInterval2String(_ time:TimeInterval) -> String {
        //재생시간의 매개변수인 time값을 60으로 나눈 몫을 정수 값으로 변환하여 상수 min에 초기화
        let min = Int(time/60)
        //time값을 60으로 나눈 나머지 값을 정수 값으로 변환하여 상수 sec 값에 초기화 한다.
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        //이 두 값을 이용해서 "%02d:%02d" 형태의 문자열로 변환하여 상수에 초기화
        let strTime = String(format: "%02d:%02d",min,sec)
        
        return strTime
        
    }
    
    
    //앞에서 만든 타이머에 의해 0.1초 간격으로 이 함수가 실행되는데, 그때마다 재생시간을 라벨과 프로그래스바에 보여준다.
    @objc func updatePlayTime() -> Void {
        lbCurrentTime.text = convertNSTimeInterval2String(audioPlayer.currentTime)
        pvProgressPlay.progress = Float(audioPlayer.currentTime/audioPlayer.duration)
    }
    
    @objc func updateRecordTime(){
        lbRecordTime.text = convertNSTimeInterval2String(audioRecorder.currentTime)
    }
    
}

