//
//  Document.swift
//  Fragaria Swift
//
//  Created by Daniele Cattaneo on 04/12/15.
//
//

import Cocoa
import Fragaria


class Document: NSDocument {
    
    
@IBOutlet var fragaria: MGSFragariaView!;


override init() {
    super.init()
}


override func windowControllerDidLoadNib(_ aController: NSWindowController) {
    super.windowControllerDidLoadNib(aController)
    fragaria.syntaxDefinitionName = "Objective-C"
    fragaria.isSyntaxColoured = true
    fragaria.showsLineNumbers = true
    fragaria.string = "// This is the future"
    self.undoManager = fragaria.undoManager
    MGSUserDefaultsController.shared().addFragaria(toManagedSet: fragaria)
}
    
    
deinit {
    MGSUserDefaultsController.shared().removeFragaria(fromManagedSet: fragaria)
}


override class var autosavesInPlace: Bool {
    return true
}

    
override var windowNibName: NSNib.Name? {
    return NSNib.Name(rawValue: "Document")
}

    
override func data(ofType typeName: String) throws -> Data {
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
}

    
override func read(from data: Data, ofType typeName: String) throws {
    throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
}


}

