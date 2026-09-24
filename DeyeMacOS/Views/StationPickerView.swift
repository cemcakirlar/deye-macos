import SwiftUI

public struct StationPickerView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Santral / İstasyon Seçin")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Takip etmek istediğiniz santrali belirleyin.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Kapat (Esc)")
            }

            List(appState.stations, id: \.self) { station in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(station.displayName)
                            .font(.headline)
                        if let id = station.resolvedId {
                            Text("ID: \(id)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if station.resolvedId == appState.selectedStationId {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                            .font(.title3)
                    }
                }
                .contentShape(Rectangle())
                .padding(.vertical, 4)
                .onTapGesture {
                    Task {
                        await appState.selectStation(station)
                        dismiss()
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .frame(height: 220)

            HStack {
                Button("Vazgeç") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()
            }
        }
        .padding(20)
        .frame(width: 440)
    }
}
