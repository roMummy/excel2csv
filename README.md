# excel2csv

使用[`CoreXLSX`](https://github.com/CoreOffice/CoreXLSX)和[`DHxlsReader`](https://github.com/dhoerl/DHlibxls)，支持excel文件(包括xls和xlsx格式)转csv文件

#### 使用
* 支持使用`fastlane`自己构建xcframework,已经编译好的[xcframework](https://github.com/roMummy/excel2csv/tree/master/build/xcframework)

```swift
let path = Bundle.main.path(forResource: "222", ofType: "xls")
// let path = Bundle.main.path(forResource: "111", ofType: "xlsx")

// to csv
do {
  let csvPath = try ExcelReaderCore.shared.convertToCSV(path: path!)
  print("成功 - \(csvPath)")
} catch {
  print("失败 - \(error.localizedDescription)")
}

// to txt
do {
  let txtPath = try ExcelReaderCore.shared.convertToTXT(path: path!)
  print("成功 - \(txtPath)")
} catch {
  print("失败 - \(error.localizedDescription)")
}
```

