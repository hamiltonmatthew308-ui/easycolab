import SwiftUI
import AppKit

struct GoogleOAuthCodeSheet: View {
    @ObservedObject var vm: StudioViewModel
    @FocusState private var isCodeFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "person.badge.key.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("粘贴 Google 授权码", "Paste Google Authorization Code"))
                        .font(.headline)
                    Text(L("在浏览器完成登录并点击 Copy 后，粘贴到下方输入框即可完成绑定。", "Sign in and click Copy in your browser, then paste the code below."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L("授权码 (4/...)", "Authorization Code (4/...)"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField(
                    L("在此粘贴浏览器复制的授权码...", "Paste the authorization code here..."),
                    text: $vm.oauthCodeText
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .focused($isCodeFieldFocused)
                .onSubmit {
                    Task { await vm.submitGoogleOAuthCode() }
                }
            }

            if !vm.oauthErrorMessage.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(vm.oauthErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            HStack(spacing: 8) {
                Button {
                    if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !clip.isEmpty {
                        vm.oauthCodeText = clip
                        Task { await vm.submitGoogleOAuthCode() }
                    } else {
                        vm.oauthErrorMessage = L("剪贴板为空，请先在浏览器点 Copy。", "Clipboard is empty. Click Copy in your browser first.")
                    }
                } label: {
                    Label(L("从剪贴板粘贴并绑定", "Paste & Bind"), systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isSubmittingOAuthCode)

                if let url = vm.lastOAuthURL {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Label(L("重开授权页", "Reopen Browser"), systemImage: "safari")
                    }
                    .disabled(vm.isSubmittingOAuthCode)
                }

                Spacer()

                Button(L("取消", "Cancel")) {
                    vm.showOAuthCodeInput = false
                    vm.oauthCodeText = ""
                    vm.oauthErrorMessage = ""
                }
                .disabled(vm.isSubmittingOAuthCode)

                Button {
                    Task { await vm.submitGoogleOAuthCode() }
                } label: {
                    if vm.isSubmittingOAuthCode {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(L("确认绑定", "Confirm"))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.oauthCodeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSubmittingOAuthCode)
            }
        }
        .padding(20)
        .frame(width: 500)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isCodeFieldFocused = true
            }
        }
    }
}
