//
//  ESPUDPLink.swift
//  Crazyflie client
//
//  Created by fanbaoying on 2020/4/29.
//  Copyright © 2020 Bitcraze. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
import AFNetworking

class ESPUDPLink: NSObject, CrtpDriver, GCDAsyncUdpSocketDelegate {

    var clientSocket: GCDAsyncUdpSocket = GCDAsyncUdpSocket()
    var mainQueue = DispatchQueue.main
    var udpError: String?
    let appPort:UInt16 = 2399
    let devicePort:UInt16 = 2390
    let udpHost = "192.168.43.42"
    var stateCallback: ((NSString) -> ())?
    fileprivate var connectCallback: ((Bool) -> ())?
    fileprivate var state = "idle" {
        didSet {
            stateCallback?(state as NSString)
        }
    }
    override init() {
        super.init()
        clientSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: mainQueue)
        do {
            try clientSocket.enableBroadcast(true)
            try clientSocket.bind(toPort: appPort, interface: udpError)
            if (udpError != nil) {
                print("error: \(String(describing: udpError))")
            } else {
                try clientSocket.beginReceiving()
            }
        } catch {
            print("catch:\(String(describing: udpError))")
        }
        state = "idle"
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        let recv = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        let showStr: NSMutableString = NSMutableString()
        showStr.append(recv! as String)
        showStr.append("\n")
        print("didReceive: \(String(describing: recv))")
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("Connection failed: \(String(describing: error))")
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("Data has been sent: \(tag)")
    }
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("Disconnect error: \(String(describing: error))")
    }
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        print("Start connecting")
    }
    func connect(_ address: String?, callback: @escaping (Bool) -> ()) {
        print("ESPUDPLink connect")
        //网络状态消息监听
        NotificationCenter.default.addObserver(self, selector: #selector(sendWifiStatus), name: NSNotification.Name.AFNetworkingReachabilityDidChange, object: nil)
        //开启网络状态消息监听
        AFNetworkReachabilityManager.shared().startMonitoring()
        connectCallback = callback
    }
    @objc func sendWifiStatus() {
        if AFNetworkReachabilityManager.shared().isReachable {
            if AFNetworkReachabilityManager.shared().isReachableViaWiFi {
                print("Connection Type：WiFi")
                state = "connected"
                connectCallback?(true)
            } else if AFNetworkReachabilityManager.shared().isReachableViaWWAN {
                print("Connection Type：mobile network")
                connectCallback?(false)
            }
        } else {
            print("Connection Type：No internet connection")
            connectCallback?(false)
        }
    }
    func disconnect() {
        print("Remove message notification")
        state = "idle"
        //关闭网络状态消息监听
        AFNetworkReachabilityManager.shared().stopMonitoring()
        //移除网络状态消息通知
        NotificationCenter.default.removeObserver(self)
    }
    
    func sendPacket(_ packet: Data, callback: ((Bool) -> ())?) {
        print("ESPUDPLink send UDP data: \(packet)")
        clientSocket.send(packet, toHost: udpHost, port: devicePort, withTimeout: -1, tag: 0)
    }
    
    func onStateUpdated(_ callback: @escaping (NSString) -> ()) {
        stateCallback = callback
    }
}
