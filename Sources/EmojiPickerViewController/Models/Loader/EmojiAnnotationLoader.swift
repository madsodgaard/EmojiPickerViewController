//
//  EmojiAnnotationLoader.swift
//
//  EmojiPickerViewController
//  https://github.com/yosshi4486/EmojiPickerViewController
// 
//  Created by yosshi4486 on 2022/02/01.
//
// ----------------------------------------------------------------------------
//
//  © 2022  yosshi4486
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//  

import Foundation
import SwiftyXMLParser
import UIKit

/**
 A type that loads emoji's annotation and tts to already loaded emojis.

 The resources which this object loads are located at `Resources/CLDR/annotation`.

 The original resource is https://github.com/unicode-org/cldr/tree/main/common/annoatations
 - https://github.com/unicode-org/cldr/tree/main/common/annoatationsDerived

 This loader loads annotations and tts following the LSDM specification.

 - SeeAlso:
  - [LSDM](https://unicode.org/reports/tr35/)

 - TODO:
 This class is not thread safe, it doesn't do anything about data race. Implements as `actor`?

 */
class EmojiAnnotationLoader: Loader {

    /**
     The emoji dictionary that contains all possible emojis for setting annotation and tts..
     */
    let emojiDictionary: [Emoji.ID : Emoji]

    /**
     The locale for which loads annotations and tts.
     */
    let annotationLocale: EmojiAnnotationLocale

    /**
     The URL where the destination resource is located.
     */
    var resourceURL: URL {
        return annotationLocale.annotationFileURL
    }

    /**
     Creates an *Emoji Annotation Loader* instance by the given locale.

     - Parameters:
       - emojiDictionary: The dictionary which the key is a `Character` and the value is a `Emoji`, for setting annotation and tts.
       - annotationLocale: The locale which is associated with the annotations and annotationsDerived files.
     */
    init(emojiDictionary: [Emoji.ID: Emoji], annotationLocale: EmojiAnnotationLocale) {

        self.emojiDictionary = emojiDictionary
        self.annotationLocale = annotationLocale

    }

    /**
     Loads an annotations data file for setting each emoji's annotation and tts property.
     */
    @MainActor func load() throws {

        // In this source, we don't have to worry about resources file errors, because the files are managed by this module, not user.
        let annotationXMLData = try! Data(contentsOf: resourceURL)
        let xml = XML.parse(annotationXMLData)

        for annotation in xml.ldml.annotations.annotation {

            let cp = annotation.attributes["cp"] // The type is string
            let character = Character(cp!)

            /*
             Some annotations are not for `.fullyQualified`, so we have to care that. This implementation is bit a complex.
             When the cp indicate minimally-qualified or unqualified emoji, assigns values to the fully-qualified version by referring the `fullyQualifiedVersion` property.
             */

            let targetEmoji: Emoji? = emojiDictionary[character]

            if annotation.attributes["type"] == "tts" {

                targetEmoji?.textToSpeach = annotation.text!
                targetEmoji?.fullyQualifiedVersion?.textToSpeach = annotation.text!

            } else {

                targetEmoji?.annotation = annotation.text!
                targetEmoji?.fullyQualifiedVersion?.annotation = annotation.text!

            }

        }

    }

}
