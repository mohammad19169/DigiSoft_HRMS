import 'dart:convert';

Map<String, dynamic> decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid JWT token: Expected 3 parts, got ${parts.length}');
    }
    
    // Add padding if needed for base64Url
    String payload = parts[1];
    switch (payload.length % 4) {
      case 2: payload += '=='; break;
      case 3: payload += '='; break;
    }
    
    final normalizedPayload = base64Url.normalize(payload);
    final decodedBytes = base64Url.decode(normalizedPayload);
    final decoded = utf8.decode(decodedBytes);
    
    print('🔓 JWT PAYLOAD DECODED:');
    final jsonData = jsonDecode(decoded);
    
    // Print all keys for debugging
    print('   Available keys in JWT: ${jsonData.keys}');
    print('   UserID: ${jsonData['UserID']}');
    print('   CompanyID: ${jsonData['CompanyID']}');
    print('   EmployeeID: ${jsonData['EmployeeID']}');
    print('   UserName: ${jsonData['UserName']}');
    print('   EmployeeCode: ${jsonData['EmployeeCode']}');
    print('   Email: ${jsonData['Email']}');
    print('   CompanyName: ${jsonData['CompanyName']}');
    print('   Expiration: ${jsonData['exp']}');
    print('   EmployeeThumbnail: ${jsonData['EmployeeThumbnail']}');
    print('   GeoFenceID: ${jsonData['GeoFenceID']}');
    
    return jsonData;
  } catch (e) {
    print('❌ JWT Decode error: $e');
    return {}; 
  }
}