//import AuthenticationServices
//import CryptoKit
//import FirebaseAuth
//import Foundation
//import SwiftUI
//
//// Adapted from https://firebase.google.com/docs/auth/ios/apple?authuser=0
//
//@available(iOS 14.0, OSX 10.16, tvOS 14.0, *)
//@available(watchOS, unavailable)
//struct SignInWithAppleFirebaseButton: View {
//
//    public typealias Body = SignInWithAppleButton
//
//    private let label: SignInWithAppleButton.Label
//    private let currentNonce: String
//    private let completion: (Result<OAuthCredential, Error>) -> Void
//
//    public init(_ label: SignInWithAppleButton.Label = .signIn, completion: @escaping (Result<OAuthCredential, Error>) -> Void) {
//        self.label = label
//        self.currentNonce = SignInWithAppleFirebaseButton.randomNonceString()
//        self.completion = completion
//    }
//
//    public var body: SignInWithAppleButton {
//        SignInWithAppleButton(label) { request in
//            request.requestedScopes = [.fullName, .email]
//            request.nonce = makeHashedNonce(currentNonce)
//        } onCompletion: { result in
//            switch result {
//            case .success(let authResult):
//                guard let appleCredential = authResult.credential as? ASAuthorizationAppleIDCredential else {
//                    completion(.failure(AuthenticationError.incompatibleCredentials))
//                    return
//                }
//                guard let appleIDToken = appleCredential.identityToken else {
//                    completion(.failure(AuthenticationError.missingIdentityToken))
//                    return
//                }
//                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
//                    completion(.failure(AuthenticationError.invalidData(appleIDToken)))
//                    return
//                }
//                // Initialize a Firebase credential.
//                let credential = OAuthProvider.credential(
//                    withProviderID: "apple.com",
//                    idToken: idTokenString,
//                    rawNonce: currentNonce)
//
//                // Sign in with Firebase.
//                completion(.success(credential))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//
//    private func makeHashedNonce(_ input: String) -> String {
//        let inputData = Data(input.utf8)
//        let hashedData = SHA256.hash(data: inputData)
//        let hashString = hashedData.compactMap {
//            return String(format: "%02x", $0)
//        }.joined()
//
//        return hashString
//    }
//
//    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
//    private static func randomNonceString(length: Int = 32) -> String {
//        precondition(length > 0)
//        let charset: Array<Character> =
//            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
//        var result = ""
//        var remainingLength = length
//
//        while remainingLength > 0 {
//            let randoms: [UInt8] = (0 ..< 16).map { _ in
//                var random: UInt8 = 0
//                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
//                if errorCode != errSecSuccess {
//                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
//                }
//                return random
//            }
//
//            randoms.forEach { random in
//                if remainingLength == 0 {
//                    return
//                }
//
//                if random < charset.count {
//                    result.append(charset[Int(random)])
//                    remainingLength -= 1
//                }
//            }
//        }
//
//        return result
//    }
//
//}
//
//final class AuthenticationError: NSError {
//
//    static let incompatibleCredentials = AuthenticationError(
//        domain: "com.henrikpanhans.SignInWithAppleFirebaseButton",
//        code: 1,
//        description: "Incompatible credentials returned by Apple")
//
//    static let missingIdentityToken = AuthenticationError(
//        domain: "com.henrikpanhans.SignInWithAppleFirebaseButton",
//        code: 2,
//        description: "Unable to fetch identity token")
//
//    static func invalidData(_ data: Data) -> AuthenticationError {
//        AuthenticationError(
//            domain: "com.henrikpanhans.SignInWithAppleFirebaseButton",
//            code: 3,
//            description: "Unable to serialize token string from data: \(data.debugDescription)")
//
//    }
//
//}
//
//extension NSError {
//
//    convenience init(domain: String, code: Int, description: String) {
//        let dictionary = [NSLocalizedDescriptionKey: description]
//        self.init(domain: domain, code: code, userInfo: dictionary)
//    }
//
//}
