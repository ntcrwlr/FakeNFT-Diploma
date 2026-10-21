import SwiftUI

struct EditProfileView: View {
    @State private var viewModel: EditProfileViewModel
    @State private var showsPhotoMenu = false
    @State private var showsPhotoLink = false
    @State private var showsExitConfirmation = false
    @State private var photoLink = ""
    @State private var saveRequested = false
    @FocusState private var focusedField: Field?
    @ScaledMetric(relativeTo: .body) private var fieldFontSize = 17
    @Environment(\.dismiss) private var dismiss

    // Persistence and navigation are supplied by the composition layer.
    private let onSave: (EditProfileViewModel) async throws -> Void
    private let onCancel: () -> Void

    private enum Field: Hashable {
        case name, biography, website
    }

    init(
        viewModel: EditProfileViewModel,
        onSave: @escaping (EditProfileViewModel) async throws -> Void = { _ in
            try await Task.sleep(for: .milliseconds(800))
        },
        onCancel: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                avatar
                    .frame(maxWidth: .infinity)
                field(title: "Имя") {
                    TextField("Имя", text: $viewModel.name)
                        .textContentType(.name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .biography }
                        .accessibilityIdentifier("profile.edit.name")
                }
                field(title: "Описание") {
                    TextField("Описание", text: $viewModel.biography, axis: .vertical)
                        .lineLimit(5...)
                        .lineSpacing(2)
                        .focused($focusedField, equals: .biography)
                        .accessibilityIdentifier("profile.edit.biography")
                }
                field(title: "Сайт") {
                    TextField("Сайт", text: $viewModel.website)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .website)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                        .accessibilityIdentifier("profile.edit.website")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .foregroundStyle(Color(uiColor: .profileForeground))
        .background(Color(uiColor: .profileBackground).ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) { navigationBar }
        .toolbar(.hidden, for: .navigationBar, .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if focusedField == nil {
                saveButton
            }
        }
        .disabled(viewModel.isSaving)
        .overlay {
            if viewModel.isSaving {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color(uiColor: .profileForeground))
                    .frame(width: 80, height: 80)
                    .background(Color(uiColor: .profileFieldBackground), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Сохранение профиля")
                    .accessibilityIdentifier("profile.edit.loading")
            }
        }
        .interactiveDismissDisabled(viewModel.hasChanges || viewModel.isSaving)
        .confirmationDialog("Фото профиля", isPresented: $showsPhotoMenu, titleVisibility: .visible) {
            Button("Изменить фото") {
                photoLink = viewModel.avatarURL?.absoluteString ?? ""
                showsPhotoLink = true
            }
            Button("Удалить фото", role: .destructive) { viewModel.removeAvatar() }
            Button("Отмена", role: .cancel) {}
        }
        .alert("Ссылка на фото", isPresented: $showsPhotoLink) {
            TextField("http://www.example.com", text: $photoLink)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Отмена", role: .cancel) {}
            Button("Сохранить") { viewModel.updateAvatar(link: photoLink) }
        }
        .alert("Уверены,\nчто хотите выйти?", isPresented: $showsExitConfirmation) {
            Button("Остаться", role: .cancel) {}
            Button("Выйти") { cancel() }
        }
        .alert("Ошибка", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("ОК", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task(id: saveRequested) {
            guard saveRequested else { return }
            let saved = await viewModel.save(using: onSave)
            saveRequested = false
            if saved { dismiss() }
        }
        .accessibilityIdentifier("profile.edit.screen")
    }

    private var navigationBar: some View {
        HStack {
            Button {
                focusedField = nil
                if viewModel.hasChanges {
                    showsExitConfirmation = true
                } else {
                    cancel()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Отмена")
            .accessibilityIdentifier("profile.edit.cancel")
            Spacer()
        }
        .buttonStyle(.plain)
        .frame(height: 36)
        .padding(.trailing, 16)
        .foregroundStyle(Color(uiColor: .profileForeground))
        .background(Color(uiColor: .profileBackground))
    }

    private var avatar: some View {
        Button {
            focusedField = nil
            showsPhotoMenu = true
        } label: {
            Group {
                if viewModel.isAvatarRemoved {
                    avatarPlaceholder
                } else if let url = viewModel.avatarURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image): image.resizable()
                        case .empty:
                            ProgressView().frame(width: 70, height: 70)
                        default: avatarPlaceholder
                        }
                    }
                } else {
                    Image(viewModel.avatarAssetName).resizable()
                }
            }
            .scaledToFill()
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(uiColor: .profileForeground))
                    .frame(width: 22, height: 22)
                    .background(Color(uiColor: .profileFieldBackground), in: Circle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Изменить фото профиля")
        .accessibilityIdentifier("profile.edit.avatar")
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .foregroundStyle(.secondary)
    }

    private var saveButton: some View {
        Button {
            focusedField = nil
            saveRequested = true
        } label: {
            Text("Сохранить")
                .font(.system(.title2, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 60)
                .foregroundStyle(Color(uiColor: .profileBackground))
                .background(Color(uiColor: .profileForeground), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(saveRequested)
        .accessibilityIdentifier("profile.edit.save")
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .profileBackground))
    }

    private func cancel() {
        onCancel()
        dismiss()
    }

    private func field<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.title2, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            content()
                .font(.system(size: fieldFontSize))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .background(Color(uiColor: .profileFieldBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview("Edit Profile (Light)") {
    EditProfileView(viewModel: EditProfileViewModel(profile: ProfileFixtures.editPreview))
}

#Preview("Edit Profile (Dark)") {
    EditProfileView(viewModel: EditProfileViewModel(profile: ProfileFixtures.editPreview))
        .preferredColorScheme(.dark)
}

#Preview("Edit Profile (Loading, Light)") {
    let model = EditProfileViewModel(profile: ProfileFixtures.editPreview)
    EditProfileView(viewModel: model)
        .task {
            _ = await model.save { _ in try await Task.sleep(for: .seconds(3600)) }
        }
}

#Preview("Edit Profile (Loading, Dark)") {
    let model = EditProfileViewModel(profile: ProfileFixtures.editPreview)
    EditProfileView(viewModel: model)
        .task {
            _ = await model.save { _ in try await Task.sleep(for: .seconds(3600)) }
        }
        .preferredColorScheme(.dark)
}
