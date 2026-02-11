abstract class Constant {
  static const github = 'https://github.com/qinshah/niceleep';

  static const issues = '$github/issues';

  static const privacy =
      'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1878154319170164032';

  /// 是否是商店版
  static const isStoreVersion = bool.fromEnvironment('isStoreVersion');
  // static const isStoreVersion = true;

  // static const userAgreement = 'https://agreement-drcn.hispace.dbankcloud.cn/index.html?lang=zh&agreementId=1872450056385254720';
}
