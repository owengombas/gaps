//
//  ChartUI.swift
//  gaps
//
//  Created by owen on 16.01.23.
//

import SwiftUI
import Charts

struct ChartUI: View {
    @Binding var values: [Measure]
    @Binding var title: String
    @Binding var xTitle: String
    @Binding var yTitle: String
    @Binding var colorTitle: String
    @Binding var colorsTitles: KeyValuePairs<String, Color>
    @Binding var showIfNotEmpty: Bool
    
    var body: some View {
        if #available(macOS 13.0, *) {
            if self.values.count > 1 || self.showIfNotEmpty {
                VStack(spacing: 40) {
                    Text(title).font(.system(size: 20)).bold()
                    
                    Chart {
                        ForEach(self.values) { shape in
                            LineMark(
                                x: .value(xTitle, shape.x),
                                y: .value(yTitle, shape.y)
                            ).foregroundStyle(by: .value(colorTitle, shape.z))
                        }
                    }.chartForegroundStyleScale(self.colorsTitles)
                    .chartXAxisLabel(xTitle)
                    .chartYAxisLabel(yTitle)
                    .frame(minHeight: 600)
                    
                    Button("Clear measurements") {
                        self.values = []
                    }
                }
            }
        }
    }
}

struct ChartUI_Previews: PreviewProvider {
    static var previews: some View {
        ChartUI(
            values: Binding.constant([]),
            title: Binding.constant(""),
            xTitle: Binding.constant(""),
            yTitle: Binding.constant(""),
            colorTitle: Binding.constant(""),
            colorsTitles: Binding.constant([:]),
            showIfNotEmpty: Binding.constant(true)
        )
    }
}
