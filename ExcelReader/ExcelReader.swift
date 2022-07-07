//
//  ExcelReader.swift
//  ExcelReader
//
//  Created by FSKJ on 2022/7/4.
//

import Foundation
import WebKit
@_implementationOnly import DHxlsReader


public enum ExcelError: Error {
    /// 文件加载失败
    case loadFileFailed
    /// 不是excel文件
    case notExcelFile
    /// 其他错误
    case other(msg: String)
}

open class ExcelReaderCore {
    public static let shared = ExcelReaderCore()
    private init() {}

    /// excel -> csv
    public func convertToCSV(path: String) throws -> String {
        let ext = NSString(string: path).pathExtension.lowercased()
        if ext == "xls" {
            return try ExcelParserOnXLS(excel: path).parser().toCSV()
        }
        if ext == "xlsx" {
            return try ExcelParserOnXLSX(excel: path).parser().toCSV()
        }
        throw ExcelError.notExcelFile
    }
    /// excel -> PDF
    public func convertToPdf(path: String, complate:@escaping (String) -> Void) throws {
        let csvPath = try convertToCSV(path: path)
        PdfConvertTool.shared.fileToPdf(csvPath) { pdfPath in
            complate(pdfPath)
        }
    }
    /// excel -> txt
    public func convertToTXT(path: String) throws -> String {
        let ext = NSString(string: path).pathExtension.lowercased()
        if ext == "xls" {
            return try ExcelParserOnXLS(excel: path).parser().toTXT()
        }
        if ext == "xlsx" {
            return try ExcelParserOnXLSX(excel: path).parser().toTXT()
        }
        throw ExcelError.notExcelFile
    }
}


// MARK: - CSV to PDF
class PdfConvertTool: NSObject {
    static let shared = PdfConvertTool()
    private override init() {
        super.init()
    }
    /// pdf渲染
    private var render: PDFRender!
    private var isCancel: Bool = false
    private var completion: ((String) -> Void)?
    
    private lazy var webView: WKWebView = {
        let view = WKWebView(frame: UIScreen.main.bounds, configuration: WKWebViewConfiguration())
        view.navigationDelegate = self
        return view
    }()
    
    /// 可以使用wkwebview加载的文件转PDF，使用wkwebview预览加打印渲染
    /// - Parameters:
    ///   - officePath: 文档路径
    ///   - completion: 回调
    func fileToPdf(_ officePath: String, completion: ((String) -> Void)?) {
        self.completion = completion
        webView.loadFileURL(URL(fileURLWithPath: officePath), allowingReadAccessTo: URL(fileURLWithPath: officePath))
    }
}
extension PdfConvertTool: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish")
        // 取消
        if isCancel {
            isCancel = false
            return
        }
        /// 保存PDF位置
        let outPath = NSTemporaryDirectory() + "test.pdf"
        // 创建打印渲染
        render = nil
        render = PDFRender()
        // 获取渲染格式
        let format = webView.viewPrintFormatter()
        // 设置渲染格式
        render.addPrintFormatter(format, startingAtPageAt: 0)
        // 将HTML渲染为PDF
        if let pdfData = render.drawPDF() {
            pdfData.write(toFile: outPath, atomically: true)
        }
        DispatchQueue.main.async {
            self.completion?(outPath)
        }
    }
}

fileprivate class PDFRender: UIPrintPageRenderer {
    // A4纸大小 595*842
    let pageFrame: CGRect = CGRect(x: 0.0, y: 0.0, width: 595.2, height: 841.8)

    var isCancel: Bool = false

    override init() {
        super.init()
        // 设置打印纸的尺寸大小
        setValue(pageFrame, forKey: "paperRect")
        // 设置内容区域大小
        setValue(pageFrame, forKey: "printableRect")
    }

    func cancel() {
        isCancel = true
    }

    /// 绘制PDF并生成NSData
    func drawPDF() -> NSData? {
        let data = NSMutableData()
        // 小心！第二个参数如果设置为CGRect.zero，PDF尺寸就会是默认的 612*792
        UIGraphicsBeginPDFContextToData(data, pageFrame, nil)
//        print("numberOfPages - \(numberOfPages)")
        if let context = UIGraphicsGetCurrentContext() {
            print("context - \(context)")
        }
        prepare(forDrawingPages: NSRange(location: 0, length: numberOfPages))

        let bounds = pageFrame
        for i in 0 ..< numberOfPages {
            if isCancel {
                UIGraphicsEndPDFContext()
                return nil
            }
            UIGraphicsBeginPDFPage()
            drawPage(at: i, in: bounds)
        }
        UIGraphicsEndPDFContext()
        return data
    }
}


// MARK: - Excel to CSV

protocol ExcelParser {
    init(excel path: String)

    var excelPath: String { get set }
    var bodyString: String {get set}

    func parser() throws -> Self
    
    func toCSV() throws -> String
    
    func toTXT() throws -> String
}

class ExcelParserOnXLSX: ExcelParser {
    var excelPath: String
    var bodyString: String = ""

    required init(excel path: String) {
        excelPath = path
    }

    func parser() throws -> Self {
        guard let file = XLSXFile(filepath: excelPath) else {
            throw ExcelError.loadFileFailed
        }
        let wbks = try file.parseWorkbooks()
        for wbk in wbks {
            // 这里拿到的sheet是反的，需要反转
            for (name, path) in try file.parseWorksheetPathsAndNames(workbook: wbk).reversed() {
                if let worksheetName = name {
                    print("This worksheet has a name: \(worksheetName)")
                    // sheet换行
                    bodyString += "\r\n"
                }
                // 获取sheet
                let worksheet = try file.parseWorksheet(at: path)
                // 获取当前string
                let sharedStrings = try file.parseSharedStrings()
                // 记录上一个row
                var lastRow: UInt = 1
                // 获取所有rows
                for row in worksheet.data?.rows ?? [] {
                    for c in row.cells {
                        let rowInt = c.reference.row
                        // 获取每一个cell的数据
                        if let sharedStrings = sharedStrings, let value = c.stringValue(sharedStrings) {
                            if lastRow != rowInt {
                                // 移除上一行末尾的 ,
                                bodyString.removeLast()
                                // 换行
                                bodyString += "\r\n"
                            }
                            // 记录数据
                            bodyString += "\"\(value)\"" + ","
                            lastRow = rowInt
                        }
                    }
                }
            }
        }
        return self
    }
    
    func toCSV() throws -> String {
        // 输出到文件里面
        let path = NSTemporaryDirectory() + "test.csv"
        try bodyString.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }
    
    func toTXT() throws -> String {
        // 输出到文件里面
        let path = NSTemporaryDirectory() + "test.txt"
        try bodyString.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }
}

class ExcelParserOnXLS: ExcelParser {
    var excelPath: String
    var bodyString: String = ""

    required init(excel path: String) {
        excelPath = path
    }

    func parser() throws -> Self {
        guard let reader = DHxlsReader.xlsReader(withPath: excelPath) else {
            throw ExcelError.loadFileFailed
        }

        let sheets = reader.numberOfSheets()
        for sheet in 0..<sheets {
            reader.startIterator(sheet)
            if let name = reader.sheetName(at: sheet) {
                print("sheet - \(name)")
            }
            // sheet换行
            bodyString += "\r\n"
            var lastRow: UInt16 = 1
            while true {
                guard let cell = reader.nextCell() else {
                    continue
                }
                if cell.type == cellBlank {break}
                if lastRow != cell.row {
                    bodyString += "\r\n"
                }
                if let str = cell.str {
                    bodyString += "\"\(str)\","
                }
                lastRow = cell.row
            }
        }
        return self
    }
    
    func toCSV() throws -> String {
        // 输出到文件里面
        let path = NSTemporaryDirectory() + "test.csv"
        try bodyString.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }
    
    func toTXT() throws -> String {
        // 输出到文件里面
        let path = NSTemporaryDirectory() + "test.txt"
        try bodyString.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }
}
