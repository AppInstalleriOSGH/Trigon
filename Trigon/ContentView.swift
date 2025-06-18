//
//  ContentView.swift
//  Trigon
//
//  Created by Benjamin on 6/18/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var Logger = LoggerClass.shared
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Button("Exploit") {
                        trigon()
                    }
                    if !Logger.log.lineFix().isEmpty {
                        Text(Logger.log.lineFix())
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                            .padding()
                    }
                }
            }
            .navigationBarTitle("Trigon", displayMode: .inline)
        }
        .navigationViewStyle(.stack)
    }
}

class LoggerClass: ObservableObject {
    @Published var log: String
    let pipe: Pipe
    let sema: DispatchSemaphore
    static let shared = LoggerClass()
    init() {
        log = ""
        pipe = Pipe()
        self.sema = DispatchSemaphore(value: 0)
        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            guard !data.isEmpty, let string = String(data: data, encoding: .utf8) else {
                fileHandle.readabilityHandler = nil
                return
            }
            DispatchQueue.main.async {
                self.log += string
                self.sema.signal()
            }
            self.sema.wait()
        }
        setvbuf(stdout, nil, _IONBF, 0)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
    }
}

extension String {
    func lineFix() -> String {
        return replacingOccurrences(of: "\\n+$", with: "", options: .regularExpression)
    }
}
