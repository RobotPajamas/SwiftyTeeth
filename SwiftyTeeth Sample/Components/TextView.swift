//
//  TextView.swift
//  SwiftyTeeth Sample
//
//  Created by SJ on 2020-03-28.
//

import Foundation
import SwiftUI

struct TextView: UIViewRepresentable {
    @Binding var text: String
    var autoscroll = false

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView().apply {
            $0.isScrollEnabled = true
            
            $0.isEditable = true
            $0.isUserInteractionEnabled = true
            $0.font = UIFont.systemFont(ofSize: 16)
            // TODO: Max characters
        }
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        if (autoscroll) {
            scrollToBottom(uiView)
        }
    }
    
    private func scrollToBottom(_ uiView: UITextView) {
        guard !text.isEmpty else {
            return
        }
        let location = text.count - 1
        let bottom = NSMakeRange(location, 1)
        uiView.scrollRangeToVisible(bottom)
    }
}


struct TextView_Previews: PreviewProvider {
    static var previews: some View {
        TextView(text: .constant("Hello World"))
    }
}
