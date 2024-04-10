//
//  OnboardingAuth.swift
//  Mac
//
//  Created by Payton Curry on 4/7/24.
//

import SwiftUI
import FluidGradient
import AuthenticationServices
import GoogleSignIn
import FirebaseAuth
import Firebase
import AppKit
import SharedQProtocol

class OBPath: ObservableObject {
    @Published var path: [String] = []
}

struct OnboardingAuth: View {
    @StateObject var obPath = OBPath()
    @AppStorage("accountSetupSheet") var showingSetupSheet = false
    @AppStorage("musicSetup") var musicSetup = false
    var body: some View {
        NavigationStack(path: $obPath.path) {
            ZStack {
                FluidGradient(blobs: [.red, .yellow],
                              highlights: [.yellow, .orange], speed: CGFloat(0.3))
                .background(.quaternary).ignoresSafeArea()
                VStack {
                    Spacer()
                    VStack {
                        Text("Welcome to SharedQ").font(.largeTitle).fontWeight(.bold)
                        Text("create a shared music queue no matter what streaming service you use")
                    }.padding()
                    Spacer()
                        SignInWithAppleFirebaseButton(.continue) { res in
                            switch res {
                            case .success(let cred):
                                //auth
                                Auth.auth().signIn(with: cred) { res, err in
                                    if err == nil {
                                        
                                        showingSetupSheet = true
                                    }
                                }
                                break;
                            case .failure(let err):
                                //fuck
                                //TODO make this not fucked
                                print(err)
                                break;
                            }
                        }.cornerRadius(10.0)
                    
                    
                    Button(action: {
                        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
                                
                        let config = GIDConfiguration(clientID: clientID)

                        GIDSignIn.sharedInstance.configuration = config
                                
                        GIDSignIn.sharedInstance.signIn(withPresenting: NSApplication.shared.mainWindow!) { signResult, error in
                                
                            if let error = error {
                               return
                            }
                                    
                             guard let user = signResult?.user,
                                   let idToken = user.idToken else { return }
                             
                             let accessToken = user.accessToken
                                    
                             let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)

                            Auth.auth().signIn(with: credential) { res, err in
                                if err == nil {
                                    showingSetupSheet = true
                                }
                            }
                        }
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10.0).foregroundStyle(.black)
                            HStack {
                                Image(.googleLogo).resizable().aspectRatio(contentMode: .fit).frame(width: 10, height: 10)
                                Text("Continue with Google").fontDesign(.rounded).fontWeight(.medium)
                            }
                        }
                    }).buttonStyle(.plain).frame(width: 375, height: 30)
                }.padding()
            }.sheet(isPresented: $showingSetupSheet, onDismiss: {
                musicSetup = true
                obPath.path.append("music-service")
            }, content: {
                AccountSetupSheet()
            }).navigationDestination(for: String.self) { str in
                switch str {
                case "music-service":
                    OnboardingMusicService().navigationBarBackButtonHidden().environmentObject(obPath)
                case "final-notes":
                    OnboardingFinal().navigationBarBackButtonHidden().environmentObject(obPath)
                default:
                    Text("Broken :(")
                }
            }.onAppear(perform: {
                if musicSetup {
                    obPath.path.append("music-service")
                }
            })
        }
    }
}

struct AccountSetupSheet: View {
    @EnvironmentObject var firManager: FIRManager
    @Environment(\.dismiss) var dismiss
    @State var username = ""
    @State var loading = false
    @AppStorage("showingSetupSheet") var accountSetup = false
    @AppStorage("musicSetup") var musicSetup = false
    var body: some View {
        VStack {
            Text("Account Setup").font(.title).fontWeight(.semibold)
            Text("set up your Shared Queue profile. all of this info will be visible to anybody in any group you're in")
            TextField("username", text: $username)
            Button {
                Task {
                    await addAccountToFirebase()
                }
            } label: {
                HStack {
                    Text("Continue")
                    Image(systemName: "chevron.right")
                }
            }.keyboardShortcut(.defaultAction).overlay(content: {
                if loading {
                    RoundedRectangle(cornerRadius: 15.0).foregroundStyle(.black).opacity(0.5)
                    ProgressView()
                }
            }).frame(height: 70).padding(.vertical)

        }.padding()
    }
    func addAccountToFirebase() async {
        if validateUsername() {
            var user = SQUser(id: Auth.auth().currentUser!.uid, username: username)
            let res = await firManager.createUser(user)
            if res {
                accountSetup = false
                
                dismiss()
                
            }
        }
    }
    func validateUsername() -> Bool {
        if username.contains(" ") { return false }
        if username.isEmpty { return false }
        return true
    }
}

struct CoolTextfieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.padding().background {
            RoundedRectangle(cornerRadius: 25.0).foregroundStyle(.gray).opacity(0.3)
        }
    }
    
}

#Preview {
    OnboardingAuth()
}

extension GeometryProxy: Equatable {
    static public func ==(lhs: GeometryProxy, rhs: GeometryProxy) -> Bool {
        return lhs.size == rhs.size
    }
}
