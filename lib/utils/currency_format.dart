extension CurrencyFormat on num {
  String toRibuan() {
    return toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String toIdr() => 'Rp ${toRibuan()}';
}
