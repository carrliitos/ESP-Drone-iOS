//
//  CrazyFlie.swift
//  Crazyflie client
//
//  Created by Martin Eberl on 15.07.16.
//  Copyright © 2016 Bitcraze. All rights reserved.
//

import UIKit

protocol CrazyFlieCommander {
    var pitch: Float { get }
    var roll: Float { get }
    var thrust: Float { get }
    var yaw: Float { get }
    
    func prepareData()
}

enum CrazyFlieHeader: UInt8 {
    case commander = 0x30
}

enum CrazyFlieState {
    case idle, connected , scanning, connecting, services, characteristics
}

protocol CrazyFlieDelegate {
    func didSend()
    func didUpdate(state: CrazyFlieState)
    func didFail(with title: String, message: String?)
}

open class CrazyFlie: NSObject {
    
    private(set) var state:CrazyFlieState {
        didSet {
            delegate?.didUpdate(state: state)
        }
    }
    private var timer:Timer?
    private var delegate: CrazyFlieDelegate?
    private(set) var crtpDriver:CrtpDriver!

    var commander: CrazyFlieCommander?
    
    init(crtpDriver:CrtpDriver? = ESPUDPLink(), delegate: CrazyFlieDelegate?) {
        
        state = .idle
        self.delegate = delegate
        
        self.crtpDriver = crtpDriver
        super.init()
    
        crtpDriver?.onStateUpdated{[weak self] (state) in
            if state.isEqual(to: "idle") {
                self?.state = .idle
            } else if state.isEqual(to: "connected") {
                self?.state = .connected
            }
        }
//        bluetoothLink?.onStateUpdated{[weak self] (state) in
//            if state.isEqual(to: "idle") {
//                self?.state = .idle
//            } else if state.isEqual(to: "connected") {
//                self?.state = .connected
//            } else if state.isEqual(to: "scanning") {
//                self?.state = .scanning
//            } else if state.isEqual(to: "connecting") {
//                self?.state = .connecting
//            } else if state.isEqual(to: "services") {
//                self?.state = .services
//            } else if state.isEqual(to: "characteristics") {
//                self?.state = .characteristics
//            }
//        }
    }
    
    func connect(_ callback:((Bool) -> Void)?) {
        guard state == .idle else {
            self.disconnect()
            return
        }
        print("CrazyFile connect")
        self.crtpDriver.connect(nil, callback: {[weak self] (connected) in
        callback?(connected)
            guard connected else {
                var title:String
                var body:String?
                
                // Find the reason and prepare a message
                title = "网络错误"
                body = "网络未连接"
                
                self?.delegate?.didFail(with: title, message: body)
                return
            }
            self?.startTimer()
        })
//        self.bluetoothLink.connect(nil, callback: {[weak self] (connected) in
//            callback?(connected)
//            guard connected else {
//                if self?.timer != nil {
//                    self?.timer?.invalidate()
//                    self?.timer = nil
//                }
//
//                var title:String
//                var body:String?
//
//                // Find the reason and prepare a message
//                if self?.bluetoothLink.getError() == "Bluetooth disabled" {
//                    title = "Bluetooth disabled"
//                    body = "Please enable Bluetooth to connect a Crazyflie"
//                } else if self?.bluetoothLink.getError() == "Timeout" {
//                    title = "Connection timeout"
//                    body = "Could not find Crazyflie"
//                } else {
//                    title = "Error";
//                    body = self?.bluetoothLink.getError()
//                }
//
//                self?.delegate?.didFail(with: title, message: body)
//                return
//            }
//
//            self?.startTimer()
//        })
    }
    
    func disconnect() {
        self.crtpDriver.disconnect()
        stopTimer()
    }
    
    // MARK: - Private Methods 
    
    private func startTimer() {
        stopTimer()

        self.timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(self.updateData), userInfo:nil, repeats:true)
    }

    private func stopTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
    }
//    NSString *str = @"abcde";
//    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
//    NSLog(@"%@", data);
//    Byte *testByte = (Byte *)[data bytes];
//    int count = 0;
//    for(int i=0;i<[data length];i++)
//    {
//        count = count + testByte[i];
//        NSLog(@"%hhu  ====  %d", testByte[i], count);
//    }
//    Byte countByte = (Byte)(0xff & count);
//    NSData *data2 = [NSData dataWithBytes:&countByte length:sizeof(countByte)];
//    NSMutableData *sendData = [NSMutableData dataWithData:data];
//    [sendData appendData:data2];
//    NSLog(@"countByte:%d === data2: %@ === sendData:%@", countByte, data2, sendData);
//
    @objc
    private func updateData(timer: Timer) {
        guard let commander = commander else {
            return
        }

        commander.prepareData()
        sendFlightData(commander.roll, pitch: commander.pitch, thrust: commander.thrust, yaw: commander.yaw)
    }
    
    private func sendFlightData(_ roll:Float, pitch:Float, thrust:Float, yaw:Float) {
        let commandPacket = CommanderPacket(header: CrazyFlieHeader.commander.rawValue, roll: roll, pitch: pitch, yaw: yaw, thrust: UInt16(thrust))
        let data = CommandPacketCreator.data(from: commandPacket)
        let sendData = self.sendDataCRC(data!)
        print("发送数据: \(sendData)")
        self.crtpDriver.sendPacket(sendData, callback: nil)
        print("pitch: \(pitch) roll: \(roll) thrust: \(thrust) yaw: \(yaw)")
    }
    func sendDataCRC(_ data:Data) -> Data {
        var sendData = data
        let sendByte = [UInt8](data)
        var count = 0
        for item in sendByte {
            print(item)
            count = count + Int(item)
//            print("字节：\(item) === 总和：\(count)")
        }
        let countByte = UInt8(count & 0xff)
        sendData.append(countByte)
        return sendData
    }
}
