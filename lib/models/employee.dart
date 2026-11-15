/// قاعدة البيانات تُعيد أعمدة Decimal كنص مثل "0.0000" أو 2200.0،
/// لذا نقرأها بتسامح بدل من `as num` الذي يرمي استثناءً.
double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim());
}

class Employee {
  final String id;
  final String name;
  final String email;
  final String department;
  final String position;
  final String managerId;
  final String role;
  final double? salary;
  final bool subjectToTax;
  final double taxRate;
  final bool subjectToInsurance;
  final double insuranceRate;
  final bool subjectToSolidarity;
  final double solidarityRate;
  final String? financialNumber;
  final String? accountNumber;
  final String? bankId;
  final String? bankBranchId;
  final String? directManagerName;
  final String? upperManagerName;
  final String? branchName;
  final String? sectionName;
  final String? unitName;
  final String? employeeNumber;
  final String? phone;
  final String? address;
  final String? birthDate;
  final String? joinDate;
  final String? photoPath;
  final String? nationalId;
  final String? maritalStatus;
  final String? gender;
  final String? bloodType;
  final String employmentStatus;
  final bool isActive;
  final double? leaveBalance;
  final double? annualLeaveAllocation;
  final List<FamilyMember>? familyMembers;
  final List<Education>? education;
  final List<Training>? training;
  final List<Performance>? performance;
  final List<EmployeeWarning>? warnings;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.position,
    required this.managerId,
    this.role = 'employee',
    this.salary,
    this.subjectToTax = false,
    this.taxRate = 0,
    this.subjectToInsurance = false,
    this.insuranceRate = 0,
    this.subjectToSolidarity = false,
    this.solidarityRate = 0,
    this.financialNumber,
    this.accountNumber,
    this.bankId,
    this.bankBranchId,
    this.directManagerName,
    this.upperManagerName,
    this.branchName,
    this.sectionName,
    this.unitName,
    this.employeeNumber,
    this.phone,
    this.address,
    this.birthDate,
    this.joinDate,
    this.photoPath,
    this.nationalId,
    this.maritalStatus,
    this.gender,
    this.bloodType,
    this.employmentStatus = '',
    this.isActive = true,
    this.leaveBalance,
    this.annualLeaveAllocation,
    this.familyMembers,
    this.education,
    this.training,
    this.performance,
    this.warnings,
  });

  bool get isManager => role == 'manager';

  factory Employee.fromJson(Map<String, dynamic> json) {
    // ملاحظة: كل الحقول تُقرأ بـ `?.toString()` بدلاً من Casting صارم
    // (`as String`)، لأن حقل ناقص أو من نوع غير متوقع كان يُسقط التطبيق
    // برسالة «type 'Null' is not a subtype of type 'String'».
    return Employee(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      managerId: json['managerId']?.toString() ?? '',
      role: json['role']?.toString() ??
          (json['position']?.toString() == 'مدير' ? 'manager' : 'employee'),
      salary: _asDouble(json['salary']),
      subjectToTax: json['subjectToTax'] == true,
      taxRate: _asDouble(json['taxRate']) ?? 0,
      subjectToInsurance: json['subjectToInsurance'] == true,
      insuranceRate: _asDouble(json['insuranceRate']) ?? 0,
      subjectToSolidarity: json['subjectToSolidarity'] == true,
      solidarityRate: _asDouble(json['solidarityRate']) ?? 0,
      financialNumber: json['financialNumber']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      bankId: json['bankId']?.toString(),
      bankBranchId: json['bankBranchId']?.toString(),
      directManagerName: json['directManagerName']?.toString(),
      upperManagerName: json['upperManagerName']?.toString(),
      branchName: json['branchName']?.toString(),
      sectionName: json['sectionName']?.toString(),
      unitName: json['unitName']?.toString(),
      employeeNumber: json['employeeNumber']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      birthDate: json['birthDate']?.toString(),
      joinDate: json['joinDate']?.toString(),
      photoPath: json['photoPath']?.toString(),
      nationalId: json['nationalId']?.toString(),
      maritalStatus: json['maritalStatus']?.toString(),
      gender: json['gender']?.toString(),
      bloodType: json['bloodType']?.toString(),
      employmentStatus: json['employmentStatus']?.toString() ?? '',
      isActive: json['isActive'] != false && json['isActive']?.toString() != 'false',
      leaveBalance: _asDouble(json['leaveBalance']),
      annualLeaveAllocation: _asDouble(json['annualLeaveAllocation']),
      familyMembers: json['familyMembers'] != null
          ? (json['familyMembers'] as List)
              .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      education: json['education'] != null
          ? (json['education'] as List)
              .map((e) => Education.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      training: json['training'] != null
          ? (json['training'] as List)
              .map((t) => Training.fromJson(t as Map<String, dynamic>))
              .toList()
          : null,
      performance: json['performance'] != null
          ? (json['performance'] as List)
              .map((p) => Performance.fromJson(p as Map<String, dynamic>))
              .toList()
          : null,
      warnings: json['warnings'] != null
          ? (json['warnings'] as List)
              .map((warning) => EmployeeWarning.fromJson(warning as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'position': position,
      'managerId': managerId,
      'role': role,
      'salary': salary,
      'subjectToTax': subjectToTax,
      'taxRate': taxRate,
      'subjectToInsurance': subjectToInsurance,
      'insuranceRate': insuranceRate,
      'subjectToSolidarity': subjectToSolidarity,
      'solidarityRate': solidarityRate,
      'financialNumber': financialNumber,
      'accountNumber': accountNumber,
      'bankId': bankId,
      'bankBranchId': bankBranchId,
      'employeeNumber': employeeNumber,
      'phone': phone,
      'address': address,
      'birthDate': birthDate,
      'joinDate': joinDate,
      'photoPath': photoPath,
      'nationalId': nationalId,
      'maritalStatus': maritalStatus,
      'gender': gender,
      'bloodType': bloodType,
      'employmentStatus': employmentStatus,
      'isActive': isActive,
      'leaveBalance': leaveBalance,
      'annualLeaveAllocation': annualLeaveAllocation,
      'familyMembers': familyMembers?.map((e) => e.toJson()).toList(),
      'education': education?.map((e) => e.toJson()).toList(),
      'training': training?.map((t) => t.toJson()).toList(),
      'performance': performance?.map((p) => p.toJson()).toList(),
      'warnings': warnings?.map((warning) => warning.toJson()).toList(),
    };
  }
}

class EmployeeWarning {
  final String? investigationNumber;
  final String? date;
  final String? description;
  final String? fileName;
  final String? fileData;

  const EmployeeWarning({
    this.investigationNumber,
    this.date,
    this.description,
    this.fileName,
    this.fileData,
  });

  factory EmployeeWarning.fromJson(Map<String, dynamic> json) => EmployeeWarning(
        investigationNumber: json['investigationNumber']?.toString(),
        date: json['date']?.toString(),
        description: json['description']?.toString(),
        fileName: json['fileName']?.toString(),
        fileData: json['fileData']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'investigationNumber': investigationNumber,
        'date': date,
        'description': description,
        'fileName': fileName,
        'fileData': fileData,
      };
}

class FamilyMember {
  final String? name;
  final String? relation;
  final String? nationalId;
  final String? birthDate;
  final String? gender;

  FamilyMember({
    this.name,
    this.relation,
    this.nationalId,
    this.birthDate,
    this.gender,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      name: json['name'] as String?,
      relation: json['relation'] as String?,
      nationalId: json['nationalId'] as String?,
      birthDate: json['birthDate'] as String?,
      gender: json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relation': relation,
      'nationalId': nationalId,
      'birthDate': birthDate,
      'gender': gender,
    };
  }
}

class Education {
  final String? year;
  final String? specialization;
  final String? university;
  final String? degree;

  Education({
    this.year,
    this.specialization,
    this.university,
    this.degree,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      year: json['year'] as String?,
      specialization: json['specialization'] as String?,
      university: json['university'] as String?,
      degree: json['degree'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'specialization': specialization,
      'university': university,
      'degree': degree,
    };
  }
}

class Training {
  final String? name;
  final String? institution;
  final String? startDate;
  final String? endDate;
  final String? grade;

  Training({
    this.name,
    this.institution,
    this.startDate,
    this.endDate,
    this.grade,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      name: json['name'] as String?,
      institution: json['institution'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      grade: json['grade'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'institution': institution,
      'startDate': startDate,
      'endDate': endDate,
      'grade': grade,
    };
  }
}

class Performance {
  final String? year;
  final String? rating;
  final String? strengths;
  final String? improvements;
  final String? recommendations;

  Performance({
    this.year,
    this.rating,
    this.strengths,
    this.improvements,
    this.recommendations,
  });

  factory Performance.fromJson(Map<String, dynamic> json) {
    return Performance(
      year: json['year'] as String?,
      rating: json['rating'] as String?,
      strengths: json['strengths'] as String?,
      improvements: json['improvements'] as String?,
      recommendations: json['recommendations'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'rating': rating,
      'strengths': strengths,
      'improvements': improvements,
      'recommendations': recommendations,
    };
  }
}
