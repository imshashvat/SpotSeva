abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class GpsFailure extends Failure {
  const GpsFailure([super.message = 'Location unavailable']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class InsufficientPointsFailure extends Failure {
  const InsufficientPointsFailure([super.message = 'Insufficient points']);
}

class CouponSoldOutFailure extends Failure {
  const CouponSoldOutFailure([super.message = 'Coupon sold out']);
}

class TooFarFailure extends Failure {
  const TooFarFailure([super.message = 'You are too far from the spot (must be within 100m)']);
}

class DailyLimitFailure extends Failure {
  const DailyLimitFailure([super.message = 'Daily check-in limit reached for this spot']);
}

class AlreadyAdoptedFailure extends Failure {
  const AlreadyAdoptedFailure([super.message = 'You already have an adopted spot, or this spot is taken']);
}
