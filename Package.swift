// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright (c) 2020 Robot Pajamas

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import PackageDescription

let package = Package(
    name: "SwiftyTeeth",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v4)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftyTeeth",
            targets: ["SwiftyTeeth"]),
        .library(
            name: "SwiftyTooth",
            targets: ["SwiftyTooth"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftyTeeth"),
        .target(
            name: "SwiftyTooth"),
//        .testTarget(
//            name: "SwiftyTeeth Tests",
//            dependencies: ["SwiftyTeeth"]),
    ],
    swiftLanguageVersions: [.v5]
)
