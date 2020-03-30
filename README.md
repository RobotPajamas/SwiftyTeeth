# SwiftyTeeth

## What is SwiftyTeeth?

SwiftyTeeth is a simple, lightweight library intended to take away some of the cruft and tediousness of using iOS BLE. It replaces CoreBluetooth's protocols and delegates with a callback-based pattern, and handles much of the code overhead associated with handling connections, discovery, reads/writes, and notifications. It is a spiritually similar library to Android's [Blueteeth](https://github.com/RobotPajamas/Blueteeth).

Both libraries were originally inspired by the simplicity and ease-of-use of [LGBluetooth](https://github.com/l0gg3r/LGBluetooth).

## High-Level

The motivation for this library was to provide an alternate (ideally - simpler) API than what iOS offers in CoreBluetooth to reduce complexity and code overhead. Another motivator was to provide an API that might make more sense 'practically' than CoreBluetooth's API, which exposes underlying implementation-specifics rather than abstracting them away.

For instance, with BLE devices, you connect to a peripheral, but in CoreBluetooth - you call connect on a manager singleton to connect to a peripheral, which makes sense for implementation-specifics (as there is only 1 Bluetooth radio which needs to manage all connections), but not semantically. In SwiftyTeeth, the 'Device' object has the connect method, the caller 'connects to a device', rather than the caller 'asks a singleton to connect to a device on it's behalf'.

## Usage

Scan for BLE devices using SwiftyTeeth with a 1 second timeout:

	SwiftyTeeth.shared.scan(for: 1) { devices in
            self.devices = devices
            self.tableView.reloadData()
        }


Alternatively, you could use the SwiftyTeethable protocol in an extension:

	extension DeviceListViewController: SwiftyTeethable {
	    func scanTapped() {
	        swiftyTeeth.scan(for: 1) { devices in
	            self.devices = devices
	            self.tableView.reloadData()
	        }
	    }
	}


Initiate a connection using a SwiftyTeeth.Device:
 
	device?.connect(complete: { isConnected in
		print("Is device connected? \(isConnected == true)")
    })


Discover Bluetooth services and characteristics:
 
	self.device?.discoverServices(complete: { services, error in
        services.forEach({
            print("Discovering characteristics for service: \($0.uuid.uuidString)")
            self.device?.discoverCharacteristics(for: $0, complete: { service, characteristics, error in
                characteristics.forEach({
                    print("App: Discovered characteristic: \($0.uuid.uuidString) in \(service.uuid.uuidString)")
                })
                
                if service == services.last {
                    print("App: All services/characteristics discovered")
                }
            })
        })
    })


Write to a connected SwiftyTeeth.Device:

	let command = Data(bytes: [0x01])
    device?.write(data: command, to: characteristic, in: service, complete: { error in
        print("Write with response successful? \(error == nil)")
    })


Read from a connected SwiftyTeeth.Device:
 
    device?.read(from: characteristic, in: service, complete: { data, error in
        print("Read value: \(data?.base64EncodedString())")
    })


Subscribe to notifications from a connected SwiftyTeeth.Device:

	device?.subscribe(to: characteristic, in: service, complete: { data, error in
        print("Subscribed value: \(data?.base64EncodedString())")
    })

Check out the sample app in `SwiftyTeeth Sample/` to see the API in action. 

## Future Directions

### Better Error handling

Error handling in a BLE library is always tricky - but generally they should be fully asynchronous. In addition, having clear and concise error conditions, alongside seamless retries is crucial.

### Queues

As mentioned in [the Blueteeth post](http://www.sureshjoshi.com/mobile/bluetooth-bluetooths-blueteeth/), Callback Hell (or rightward drift) sucks, but that hasn't yet been solved in this library. The current usage for chaining calls is still, unfortunately, callbacks in callbacks.

### MacOS

CoreBluetooth is also available on MacOS, so once completed and compiled correctly - there is no reason that it couldn't be used directly on a Mac, rather than only from iOS devices.

### SwiftyTeeth as a Peripheral

For the purposes of testing and debugging, being able to use a Mac as a demo-peripheral has immense value. CoreBluetooth supports central and peripheral modes of operation, so this would be a great (and useful) extension.

### Reactive Everything!

Now that this library is released and progressively becoming more stable, the next step in the process is to create Reactive bindings (RxSwift bindings specifically). They will be created in a separate repo, so that there isn't a forced, heavy dependency on the Rx framework in any app that just wants to use SwiftyTeeth.


## Requirements

* iOS 10+
* Swift 5+
* XCode 10+

## Download

### CocoaPods

Currently, you can use the master or develop branches and git directly until the API has stabilized.

	platform :ios, '9.0'
	use_frameworks!

    pod 'SwiftyTeeth', :git => 'https://github.com/RobotPajamas/SwiftyTeeth.git', :branch => 'master'

### Carthage

Instructions coming soon.

## Issues

Please report all bugs or feature requests to: https://github.com/RobotPajamas/SwiftyTeeth/issues

## Swifty Community

Other iOS-centric Bluetooth libraries.

* [RxSwiftyTeeth](https://github.com/RobotPajamas/RxSwiftyTeeth)
* [BluetoothKit](https://github.com/rhummelmose/BluetoothKit)
* [Bluetonium](https://github.com/e-sites/Bluetonium)
* [RxBluetoothKit](https://github.com/Polidea/RxBluetoothKit)
* [BlueCap](https://github.com/troystribling/BlueCap)
* [Swift-LightBlue](https://github.com/Pluto-Y/Swift-LightBlue)
* [PromiseKit/CoreBluetooth](https://github.com/PromiseKit/CoreBluetooth)
* [RedBearLab](https://github.com/RedBearLab/iOS)
* [SwiftyBluetooth](https://github.com/tehjord/SwiftyBluetooth)
* [LGBluetooth](https://github.com/LGBluetooth/LGBluetooth)
* [RZBluetooth](https://github.com/Raizlabs/RZBluetooth)

## License

The Apache License (Apache)

    Copyright (c) 2019 Robot Pajamas

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
