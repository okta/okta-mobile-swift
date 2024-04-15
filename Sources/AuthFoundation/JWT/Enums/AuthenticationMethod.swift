//
// Copyright (c) 2024-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import Foundation

/// Defines the possible values for Authentication Methods, used within ``JWT/authenticationMethods``.
public enum AuthenticationMethod: String, ClaimConvertable, IsClaim {
    /// Facial recognition
    case facialRecognition = "face"
    
    /// Fingerprint biometric
    case fingerprintBiometric = "fpt"
    
    /// Geolocation
    case geolocation = "geo"
    
    /// Proof-of-possession of a hardware-secured key
    case proofOfPossessionHardware = "hwk"
    
    /// Iris scan biometric
    case irisScanBiometric = "iris"
    
    /// Knowledge-based authentication
    case knowledgeBased = "kba"
    
    /// Multiple-channel authentication
    case multipleChannel = "mca"
    
    /// Multiple-factor authentication
    case multipleFactor = "mfa"
    
    /// One-time password
    case oneTimePassword = "otp"
    
    /// Personal Identification Number or pattern
    case pin
    
    /// Proof-of-possession of a key
    case proofOfPossession = "pop"
    
    /// Password-based authentication
    case passwordBased = "pwd"
    
    /// Risk-based authentication
    case riskBased = "rba"
    
    /// Retina scan biometric
    case retinaScanBiometric = "retina"
    
    /// Smart card
    case smartCard = "sc"
    
    /// Confirmation using SMS
    case smsConfirmation = "sms"
    
    /// Proof-of-possession of a software-secured key
    case proofOfPossessionSoftware = "swk"
    
    /// Confirmation by telephone call
    case telephoneConfirmation = "tel"
    
    /// User presence test
    case userPresence = "user"
    
    /// Voice biometric
    case voiceBiometric = "vbm"
    
    /// Windows integrated authentication
    case windowsIntegrated = "wia"
}
