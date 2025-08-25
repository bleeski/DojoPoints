import SwiftUI

struct SegmentedBucketPicker: View {
    @Binding var selectedBucket: TimeBucket
    
    var body: some View {
        Picker("Time Period", selection: $selectedBucket) {
            ForEach(TimeBucket.allCases) { bucket in
                Text(bucket.rawValue)
                    .tag(bucket)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}
