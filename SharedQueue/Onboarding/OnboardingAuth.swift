//
//  OnboardingAuth.swift
//  SharedQueue
//
//  Created by Payton Curry on 3/24/24.
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn
import SharedQProtocol
import FluidGradient
import UIPilot

enum OnboardingPages: Equatable {
    case auth
    case musicService
    case finalNotes
}




struct OnboardingAuth: View {
    @EnvironmentObject var firManager: FIRManager
    @EnvironmentObject var pilot: UIPilot<OnboardingPages>
    @AppStorage("accountCreated") var accountCreated = false
    @AppStorage("accountSetup") var accountSetup = false
    
    @State var showingSetupSheet = false
    @State var emailAndPasswordSignupSheet = false
    @State var emailAndPasswordLoginSheet = false
    var body: some View {
            ZStack {
                FluidGradient(blobs: [.red, .yellow],
                              highlights: [.yellow, .orange], speed: CGFloat(0.3))
                .background(.quaternary).ignoresSafeArea()
                VStack {
                    Text("SharedQ").font(.title).fontWeight(.semibold)
                    Text("create a shared music queue no matter what streaming service you use")
                    Spacer()
//                    SignInWithAppleFirebaseButton(.continue) { res in
//                        switch res {
//                        case .success(let cred):
//                            //auth
//                            Auth.auth().signIn(with: cred) { res, err in
//                                if err == nil {
//                                    accountCreated = true
//                                    showingSetupSheet = true
//                                }
//                            }
//                            break;
//                        case .failure(let err):
//                            //fuck
//                            //TODO make this not fucked
//                            print(err)
//                            break;
//                        }
//                    }.signInWithAppleButtonStyle(.white).cornerRadius(15.0).frame(height: 50)
//                    SignInWithGoogleButton {
//                        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
//                                
//                        let config = GIDConfiguration(clientID: clientID)
//
//                        GIDSignIn.sharedInstance.configuration = config
//                                
//                        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { signResult, error in
//                                
//                            if let error = error {
//                               return
//                            }
//                                    
//                             guard let user = signResult?.user,
//                                   let idToken = user.idToken else { return }
//                             
//                             let accessToken = user.accessToken
//                                    
//                             let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
//
//                            Auth.auth().signIn(with: credential) { res, err in
//                                if err == nil {
//                                    accountCreated = true
//                                    showingSetupSheet = true
//                                }
//                            }
//                        }
//
//                    }.frame(height: 50)
                    Button(action: {
                        emailAndPasswordSignupSheet = true
                    }, label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15.0).preferredColorScheme(.dark).foregroundStyle(.ultraThinMaterial)
                            Text("\(Image(systemName: "envelope.fill")) Sign Up with Email")
                        }.foregroundStyle(.white)
                    }).frame(height: 50)
                    Button(action: {
                        emailAndPasswordLoginSheet = true
                    }, label: {
                        Text("Already have an account? **Log in**").foregroundStyle(.white)
                    }).padding()
                }.padding()
            }.preferredColorScheme(.dark).sheet(isPresented: $showingSetupSheet, onDismiss: {
                print("showing musicservice")
//                obPath.path.append("music-service")
                pilot.push(.musicService)
            }, content: {
                AccountSetupSheet().presentationDetents([.fraction(0.5)]).presentationCornerRadius(50).interactiveDismissDisabled()
            }).sheet(isPresented: $emailAndPasswordSignupSheet, onDismiss: {
//                obPath.path.append("music-service")
            }, content: {
                EmailPasswordAuthSheet().presentationDetents([.fraction(0.5)]).presentationCornerRadius(40)
            }).sheet(isPresented: $emailAndPasswordLoginSheet, content: {
                EmailPasswordAuthSheet(signUp: false).presentationDetents([.fraction(0.5)]).presentationCornerRadius(40)
            }).onAppear {
            if accountSetup {
//                obPath.path.append("music-service")
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
//            var user = SQUser(id: Auth.auth().currentUser!., username: username)
//            let res = await firManager.createUser(user)
//            if res {
//                accountSetup = true
//                dismiss()
//            }
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

struct EmailPasswordAuthSheet: View {
    var signUp: Bool = true
    @EnvironmentObject var pilot: UIPilot<OnboardingPages>
    @Environment(\.dismiss) var dismiss
    @State var email: String = ""
    @State var password: String = ""
    @State var username: String = ""
    @AppStorage("accountSetup") var accountSetup = false
    @AppStorage("accountCreated") var accountCreated = false
    @State var errorText: String?
    @State var latestRes: SQSignUpResponse?
    var body: some View {
        VStack {
            TextField("Email", text: $email).textFieldStyle(CoolTextfieldStyle()).padding()
            SecureField("Password", text: $password).textFieldStyle(CoolTextfieldStyle()).padding()
            if signUp {
                TextField("username", text: $username).textFieldStyle(CoolTextfieldStyle()).padding()
            }
            if let errorText = errorText {
                Text(errorText).foregroundStyle(.red)
            }
            if let latestRes = latestRes {
                if latestRes == .incorrectPassword {
                    Button(action: {
                        if email != "" {
                            Task {
                                await FIRManager.shared.sendPasswordResetEmail(email: email)
                            }
                        }
                    }, label: {
                        Text("Maybe try resetting your password?")
                    })
                }
            }
            GradientButton {
                if signUp {
                    if validateUsername() {
                        Task {
                            let res = await FIRManager.shared.signUp(username:username, email:email, password:password)
                            if res == .success {
                                accountSetup = true
                                accountCreated = true
                                pilot.push(.musicService)
                                dismiss()
                            } else {
                                errorText = res.rawValue
                            }
                            latestRes = res
                        }
                    } else {
                        errorText = "That username doesn't work. Please try again."
                    }
                } else {
                    Task {
                        let res = await FIRManager.shared.signIn(email: email, password: password)
                        if res == .success {
                            accountSetup = true
                            accountCreated = true
    //                        obPath.path.append("music-service")
                            pilot.push(.musicService)
                            dismiss()
                        } else {
                            errorText = res.rawValue
                        }
                        latestRes = res
                    }
                }
            } label: {
                if signUp {
                    Text("Sign Up")
                } else {
                    Text("Log In")
                }
            }.frame(height: 70).padding()
            if !signUp {
                Button(action: {
                    if email != "" {
                        Task {
                            await FIRManager.shared.sendPasswordResetEmail(email: email)
                        }
                    }
                }, label: {
                    Text("Forgot your password?")
                })
            }
            Spacer()

        }
    }
    func validateUsername() -> Bool {
        if username.contains(" ") { return false }
        if username.isEmpty { return false }
        return true
    }
}

#Preview {
    OnboardingAuth()
}
