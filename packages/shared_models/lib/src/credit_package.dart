class CreditPackage {
  final String id;
  final int credits;
  final String title;
  final String description;

  const CreditPackage({
    required this.id,
    required this.credits,
    required this.title,
    required this.description,
  });

  static List<CreditPackage> defaults = const [
    CreditPackage(
      id: 'CREDIT_50',
      credits: 50,
      title: 'Starter 50',
      description: '50 analyses for launching new stores.',
    ),
    CreditPackage(
      id: 'CREDIT_250',
      credits: 250,
      title: 'Studio 250',
      description: '250 analyses to power campaign bursts.',
    ),
    CreditPackage(
      id: 'CREDIT_1000',
      credits: 1000,
      title: 'Agency 1000',
      description: '1000 analyses tailored for agencies.',
    ),
  ];
}
