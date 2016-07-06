# QR code module, using goqr.me

# Written by Adam Chesak.
# Released under the MIT open source license.


import strutils
import json
import httpclient
import cgi


type
    QRCharset* {.pure.} = enum
        UTF8, ISO88591
    QRErrorCorrection* {.pure.} = enum
        Low, Middle, Quality, High,
        L,   M,      Q,       H
    QRFormat* {.pure.} = enum
        PNG, GIF, JPEG, JPG, SVG, EPS
    
    QRCode* = ref QRCodeInternal
    
    QRCodeInternal* = object
        url* : string
        qrCode* : string
        data* : string
        size* : int
        charsetSource* : QRCharset
        charsetTarget* : QRCharset
        ecc* : QRErrorCorrection
        color* : string
        bgcolor* : string
        margin* : int
        qzone* : int
        format* : QRFormat
    


const CREATE_URL : string = "http://api.qrserver.com/v1/create-qr-code/?"
const READ_URL : string = "http://api.qrserver.com/v1/read-qr-code/?"


proc buildCreateURL(data : string, size : int = 200, charsetSource : QRCharset = QRCharset.UTF8, charsetTarget : QRCharset = QRCharset.UTF8,
                    ecc : QRErrorCorrection = QRErrorCorrection.Low, color : string = "0-0-0", bgcolor : string = "0-0-0",
                    margin : int = 1, qzone : int = 0, format : QRFormat = QRFormat.PNG): string = 
    ## Internal proc. Builds the URL for creating a QR code.
    
    var url : string = CREATE_URL & "data=" & encodeURL(data)
    url &= "&size=" & intToStr(size) & "x" & intToStr(size)
    
    if charsetSource == QRCharset.UTF8:
        url &= "&charset-source=UTF-8"
    elif charsetSource == QRCharset.ISO88591:
        url &= "&charset-source=ISO-8859-1"
        
    if charsetTarget == QRCharset.UTF8:
        url &= "&charset-target=UTF-8"
    elif charsetTarget == QRCharset.ISO88591:
        url &= "&charset-target=ISO-8859-1"
    
    if ecc == QRErrorCorrection.Low or ecc == QRErrorCorrection.L:
        url &= "&ecc=L"
    elif ecc == QRErrorCorrection.Middle or ecc == QRErrorCorrection.M:
        url &= "&ecc=M"
    elif ecc == QRErrorCorrection.Quality or ecc == QRErrorCorrection.Q:
        url &= "&ecc=Q"
    elif ecc == QRErrorCorrection.High or ecc == QRErrorCorrection.H:
        url &= "&ecc=H"
    
    url &= "&color=" & color
    url &= "&bgcolor=" & bgcolor
    
    url &= "&margin=" & intToStr(margin)
    url &= "&qzone=" & intToStr(qzone)
    
    if format == QRFormat.PNG:
        url &= "&format=png"
    elif format == QRFormat.GIF:
        url &= "&format=gif"
    elif format == QRFormat.JPEG:
        url &= "&format=jpeg"
    elif format == QRFormat.JPG:
        url &= "&format=jpg"
    elif format == QRFormat.SVG:
        url &= "&format=svg"
    elif format == QRFormat.EPS:
        url &= "&format=eps"
    
    return url


proc createQR*(data : string, size : int = 200, charsetSource : QRCharset = QRCharset.UTF8, charsetTarget : QRCharset = QRCharset.UTF8,
               ecc : QRErrorCorrection = QRErrorCorrection.Low, color : string = "ffffff", bgcolor : string = "000000",
               margin : int = 1, qzone : int = 0, format : QRFormat = QRFormat.PNG): QRCode = 
    ## Creates a QR code from the given `data`.
    ##
    ## All other parameters are optional. See the API documentation at http://goqr.me/api/doc/create-qr-code/ for details.
    
    var qr : QRCode = QRCode(data: data, size: size, charsetSource: charsetSource, charsetTarget: charsetTarget, ecc: ecc,
                             color: color, bgcolor: bgcolor, margin: margin, qzone: qzone, format: format)
    
    var url = buildCreateURL(data, size, charsetSource, charsetTarget, ecc, color, bgcolor, margin, qzone, format)
    qr.url = url
    
    var response : string = getContent(url)
    qr.qrCode = response
    
    return qr


proc saveQR*(data : string, filename : string, size : int = 200, charsetSource : QRCharset = QRCharset.UTF8, charsetTarget : QRCharset = QRCharset.UTF8,
               ecc : QRErrorCorrection = QRErrorCorrection.Low, color : string = "ffffff", bgcolor : string = "000000",
               margin : int = 1, qzone : int = 0, format : QRFormat = QRFormat.PNG): QRCode = 
    ## Creates a QR code from the given `data` and saves to the specified `filename`.
    ##
    ## All other parameters are optional. See the API documentation at http://goqr.me/api/doc/create-qr-code/ for details.
    
    var qr : QRCode = createQR(data, size, charsetSource, charsetTarget, ecc, color, bgcolor, margin, qzone, format)
    
    var f : File = open(filename, fmWrite)
    f.write(qr.qrcode)
    f.close()
    
    return qr


proc readQR*(fileurl : string): string = 
    ## Reads the data contained in the QR code at the given ``fileurl``.
    
    var url : string = READ_URL & "fileurl=" & encodeURL(fileurl)
    var data : JsonNode = parseJson(getContent(url))
    
    return data[0]["symbol"][0]["data"].str
