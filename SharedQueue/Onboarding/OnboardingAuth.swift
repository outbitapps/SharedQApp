//
//  OnboardingAuth.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import GoogleSignIn
import Firebase
import SharedQProtocol

struct OnboardingAuth: View {
    @EnvironmentObject var firManager: FIRManager
    @AppStorage("accountCreated") var accountCreated = false
    @AppStorage("accountSetup") var accountSetup = false
    @ObservedObject var obPath: OnboardingPath = OnboardingPath()
    @State var showingSetupSheet = false
    var body: some View {
        NavigationStack(path: $obPath.path) {
            ZStack {
                LinearGradient(colors: [Color.appGradient1, Color.appGradient2], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                VStack {
                    Text("Shared Queue").font(.title).fontWeight(.semibold)
                    Text("create a shared music queue no matter what streaming service you use")
                    Spacer()
                    SignInWithAppleFirebaseButton(.continue) { res in
                        switch res {
                        case .success(let cred):
                            //auth
                            Auth.auth().signIn(with: cred) { res, err in
                                if err == nil {
                                    accountCreated = true
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
                    }.signInWithAppleButtonStyle(.white).cornerRadius(15.0).frame(height: 50)
                    SignInWithGoogleButton {
                        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
                                
                        let config = GIDConfiguration(clientID: clientID)

                        GIDSignIn.sharedInstance.configuration = config
                                
                        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { signResult, error in
                                
                            if let error = error {
                               return
                            }
                                    
                             guard let user = signResult?.user,
                                   let idToken = user.idToken else { return }
                             
                             let accessToken = user.accessToken
                                    
                             let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)

                            Auth.auth().signIn(with: credential) { res, err in
                                if err == nil {
                                    accountCreated = true
                                    showingSetupSheet = true
                                }
                            }
                        }

                    }.frame(height: 50)

                }.padding()
            }.preferredColorScheme(.dark).sheet(isPresented: $showingSetupSheet, onDismiss: {
                print("showing musicservice")
                obPath.path.append("music-service")
            }, content: {
                AccountSetupSheet().presentationDetents([.fraction(0.5)]).presentationCornerRadius(50).interactiveDismissDisabled()
            }).navigationDestination(for: String.self) { path in
                switch path {
                case "music-service":
                    OnboardingMusicService().environmentObject(obPath)
                case "final-notes":
                    OnboardingFinal().environmentObject(obPath)
                default:
                    Text("FUCK!!")
                }
            }
        }.onAppear {
            if accountSetup {
                obPath.path.append("music-service")
            } else {
                showingSetupSheet = accountCreated
            }
            
            
        }
    }
}

struct AccountSetupSheet: View {
    @EnvironmentObject var firManager: FIRManager
    @State var username = ""
    @State var loading = false
    @Environment(\.dismiss) var dismiss
    @AppStorage("accountSetup") var accountSetup = false
    var body: some View {
        VStack {
            Text("Account Setup").font(.title).fontWeight(.semibold)
            Text("set up your Shared Queue profile. all of this info will be visible to anybody in any group you're in")
            TextField("username", text: $username).textFieldStyle(CoolTextfieldStyle())
            GradientButton {
                Task {
                    await addAccountToFirebase()
                }
            } label: {
                HStack {
                    Text("Continue")
                    Image(systemName: "chevron.right")
                }
            }.overlay(content: {
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
                accountSetup = true
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