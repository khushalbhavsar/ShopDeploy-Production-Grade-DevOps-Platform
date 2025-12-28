import { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { useParams, Link } from 'react-router-dom';
import { fetchOrderById, cancelOrder } from '../features/orders/orderSlice';
import { formatPrice, formatDate } from '../utils/helpers';
import toast from 'react-hot-toast';

const OrderDetails = () => {
  const { id } = useParams();
  const dispatch = useDispatch();
  const { currentOrder, isLoading } = useSelector((state) => state.orders);
  const [isCancelling, setIsCancelling] = useState(false);

  useEffect(() => {
    if (id) {
      dispatch(fetchOrderById(id));
    }
  }, [dispatch, id]);

  const handleCancelOrder = async () => {
    if (window.confirm('Are you sure you want to cancel this order? This action cannot be undone.')) {
      setIsCancelling(true);
      try {
        await dispatch(cancelOrder(id)).unwrap();
        toast.success('Order cancelled successfully');
      } catch (error) {
        toast.error(error || 'Failed to cancel order');
      } finally {
        setIsCancelling(false);
      }
    }
  };

  if (isLoading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="flex justify-center items-center min-h-[400px]">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
        </div>
      </div>
    );
  }

  if (!currentOrder) {
    return (
      <div className="container mx-auto px-4 py-8">
        <div className="text-center">
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Order not found</h2>
          <Link to="/orders" className="text-primary-600 hover:text-primary-700">
            Back to Orders
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-6">
        <Link to="/orders" className="text-primary-600 hover:text-primary-700 flex items-center gap-2">
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
          Back to Orders
        </Link>
      </div>

      {currentOrder.currentStatus !== 'cancelled' && 
       currentOrder.currentStatus !== 'delivered' && (
        <div className="mb-6">
          <button
            onClick={handleCancelOrder}
            disabled={isCancelling}
            className="w-full md:w-auto px-6 py-3 bg-red-600 text-white font-semibold rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition duration-150 flex items-center justify-center gap-2"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
            {isCancelling ? 'Cancelling Order...' : 'Cancel This Order'}
          </button>
        </div>
      )}

      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        {/* Header */}
        <div className="bg-gradient-to-r from-primary-600 to-primary-700 text-white px-6 py-6">
          <div className="flex flex-wrap justify-between items-center gap-4">
            <div>
              <h1 className="text-2xl font-bold mb-2">
                Order #{currentOrder._id.slice(-8).toUpperCase()}
              </h1>
              <p className="text-primary-100">
                Placed on {formatDate(currentOrder.createdAt)}
              </p>
            </div>
            <div className="text-right">
              <p className="text-3xl font-bold mb-2">
                {formatPrice(currentOrder.totalAmount)}
              </p>
              <span
                className={`inline-block px-4 py-2 rounded-full text-sm font-semibold ${
                  currentOrder.currentStatus === 'delivered'
                    ? 'bg-green-100 text-green-800'
                    : currentOrder.currentStatus === 'cancelled'
                    ? 'bg-red-100 text-red-800'
                    : 'bg-yellow-100 text-yellow-800'
                }`}
              >
                {currentOrder.currentStatus?.toUpperCase() || 'PENDING'}
              </span>
            </div>
          </div>
        </div>

        {/* Order Items */}
        <div className="p-6 border-b">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Order Items</h2>
          <div className="space-y-4">
            {currentOrder.items && currentOrder.items.map((item) => (
              <div
                key={item._id}
                className="flex items-center gap-4 p-4 bg-gray-50 rounded-lg"
              >
                <img
                  src={item.image || 'https://via.placeholder.com/100'}
                  alt={item.title}
                  className="w-24 h-24 object-cover rounded-md"
                />
                <div className="flex-1">
                  <h3 className="font-semibold text-gray-900 text-lg">
                    {item.title}
                  </h3>
                  <p className="text-gray-600 mt-1">
                    Quantity: <span className="font-medium">{item.qty}</span>
                  </p>
                  <p className="text-gray-600">
                    Price: <span className="font-medium">{formatPrice(item.price)}</span>
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-xl font-bold text-gray-900">
                    {formatPrice(item.price * item.qty)}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Order Summary */}
        <div className="p-6 bg-gray-50 border-b">
          <h2 className="text-xl font-bold text-gray-900 mb-4">Order Summary</h2>
          <div className="space-y-3">
            <div className="flex justify-between text-gray-700">
              <span>Items Price:</span>
              <span className="font-medium">{formatPrice(currentOrder.itemsPrice)}</span>
            </div>
            <div className="flex justify-between text-gray-700">
              <span>Shipping Price:</span>
              <span className="font-medium">
                {currentOrder.shippingPrice === 0 ? 'FREE' : formatPrice(currentOrder.shippingPrice)}
              </span>
            </div>
            <div className="flex justify-between text-gray-700">
              <span>Tax (18% GST):</span>
              <span className="font-medium">{formatPrice(currentOrder.taxPrice)}</span>
            </div>
            <div className="flex justify-between text-xl font-bold text-gray-900 pt-3 border-t">
              <span>Total Amount:</span>
              <span>{formatPrice(currentOrder.totalAmount)}</span>
            </div>
          </div>
        </div>

        {/* Shipping & Payment Info */}
        <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
          {/* Shipping Address */}
          <div>
            <h2 className="text-xl font-bold text-gray-900 mb-4">Shipping Address</h2>
            <div className="bg-gray-50 p-4 rounded-lg">
              <p className="font-semibold text-gray-900">{currentOrder.shippingAddress.fullName}</p>
              <p className="text-gray-700 mt-2">{currentOrder.shippingAddress.addressLine1}</p>
              {currentOrder.shippingAddress.addressLine2 && (
                <p className="text-gray-700">{currentOrder.shippingAddress.addressLine2}</p>
              )}
              <p className="text-gray-700">
                {currentOrder.shippingAddress.city}, {currentOrder.shippingAddress.state} {currentOrder.shippingAddress.pincode}
              </p>
              <p className="text-gray-700">{currentOrder.shippingAddress.country || 'India'}</p>
              <p className="text-gray-700 mt-2">Phone: {currentOrder.shippingAddress.phone}</p>
            </div>
          </div>

          {/* Payment Info */}
          <div>
            <h2 className="text-xl font-bold text-gray-900 mb-4">Payment Information</h2>
            <div className="bg-gray-50 p-4 rounded-lg">
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-gray-700">Payment Method:</span>
                  <span className="font-semibold text-gray-900 uppercase">
                    {currentOrder.paymentMethod}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-700">Payment Status:</span>
                  <span
                    className={`font-semibold ${
                      currentOrder.paymentStatus === 'paid'
                        ? 'text-green-600'
                        : currentOrder.paymentStatus === 'failed'
                        ? 'text-red-600'
                        : 'text-yellow-600'
                    }`}
                  >
                    {currentOrder.paymentStatus?.toUpperCase() || 'PENDING'}
                  </span>
                </div>
                {currentOrder.paymentId && (
                  <div className="flex justify-between">
                    <span className="text-gray-700">Payment ID:</span>
                    <span className="font-mono text-sm text-gray-900">
                      {currentOrder.paymentId}
                    </span>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Order Status History */}
        {currentOrder.statusHistory && currentOrder.statusHistory.length > 0 && (
          <div className="p-6 border-t">
            <h2 className="text-xl font-bold text-gray-900 mb-4">Order Status History</h2>
            <div className="space-y-3">
              {currentOrder.statusHistory.map((history, index) => (
                <div
                  key={index}
                  className="flex items-center gap-4 p-3 bg-gray-50 rounded-lg"
                >
                  <div className="flex-shrink-0 w-3 h-3 bg-primary-600 rounded-full"></div>
                  <div className="flex-1">
                    <p className="font-semibold text-gray-900 capitalize">
                      {history.status}
                    </p>
                    {history.note && (
                      <p className="text-sm text-gray-600 mt-1">{history.note}</p>
                    )}
                  </div>
                  <div className="text-sm text-gray-500">
                    {formatDate(history.timestamp)}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default OrderDetails;
