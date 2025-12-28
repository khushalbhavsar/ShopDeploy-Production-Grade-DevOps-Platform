import { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { Link } from 'react-router-dom';
import { fetchMyOrders, cancelOrder } from '../features/orders/orderSlice';
import { formatPrice, formatDate, getStatusColor } from '../utils/helpers';
import toast from 'react-hot-toast';

const Orders = () => {
  const dispatch = useDispatch();
  const { user } = useSelector((state) => state.auth);
  const { orders, isLoading } = useSelector((state) => state.orders);
  const [cancellingId, setCancellingId] = useState(null);

  useEffect(() => {
    if (user) {
      dispatch(fetchMyOrders());
    }
  }, [dispatch, user]);

  const handleCancelOrder = async (orderId) => {
    if (window.confirm('Are you sure you want to cancel this order?')) {
      setCancellingId(orderId);
      try {
        await dispatch(cancelOrder(orderId)).unwrap();
        toast.success('Order cancelled successfully');
      } catch (error) {
        toast.error(error || 'Failed to cancel order');
      } finally {
        setCancellingId(null);
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

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold text-gray-900 mb-8">My Orders</h1>

      {orders && orders.length === 0 ? (
        <div className="text-center py-12">
          <div className="bg-white rounded-lg shadow-md p-8">
            <svg
              className="mx-auto h-24 w-24 text-gray-400 mb-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"
              />
            </svg>
            <h2 className="text-2xl font-semibold text-gray-700 mb-2">
              No Orders Yet
            </h2>
            <p className="text-gray-600 mb-6">
              You haven&apos;t placed any orders yet. Start shopping to see your orders here!
            </p>
            <Link
              to="/products"
              className="inline-block bg-primary-600 text-white px-6 py-3 rounded-lg hover:bg-primary-700 transition duration-150"
            >
              Browse Products
            </Link>
          </div>
        </div>
      ) : (
        <div className="space-y-6">
          {orders.map((order) => (
            <div
              key={order._id}
              className="bg-white rounded-lg shadow-md overflow-hidden"
            >
              <div className="bg-gray-50 px-6 py-4 border-b">
                <div className="flex flex-wrap justify-between items-center gap-4">
                  <div>
                    <p className="text-sm text-gray-600">
                      Order #{order._id.slice(-8).toUpperCase()}
                    </p>
                    <p className="text-sm text-gray-500">
                      Placed on {formatDate(order.createdAt)}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-lg font-semibold text-gray-900">
                      {formatPrice(order.totalAmount)}
                    </p>
                    <span
                      className={`inline-block px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(
                        order.currentStatus || 'pending'
                      )}`}
                    >
                      {order.currentStatus || 'pending'}
                    </span>
                  </div>
                </div>
              </div>

              <div className="p-6">
                <div className="space-y-4">
                  {order.items && order.items.map((item) => (
                    <div
                      key={item._id}
                      className="flex items-center gap-4 border-b pb-4 last:border-b-0"
                    >
                      <img
                        src={item.image || 'https://via.placeholder.com/80'}
                        alt={item.title}
                        className="w-20 h-20 object-cover rounded-md"
                      />
                      <div className="flex-1">
                        <h3 className="font-medium text-gray-900">
                          {item.title}
                        </h3>
                        <p className="text-sm text-gray-600">
                          Quantity: {item.qty}
                        </p>
                      </div>
                      <p className="font-semibold text-gray-900">
                        {formatPrice(item.price * item.qty)}
                      </p>
                    </div>
                  ))}
                </div>

                <div className="mt-6 pt-4 border-t">
                  <div className="flex justify-between items-center">
                    <div className="text-sm text-gray-600">
                      <p>
                        Shipping to: {order.shippingAddress.addressLine1},{' '}
                        {order.shippingAddress.city}
                      </p>
                    </div>
                    <div className="flex items-center gap-3">
                      {order.currentStatus !== 'cancelled' && 
                       order.currentStatus !== 'delivered' && (
                        <button
                          onClick={() => handleCancelOrder(order._id)}
                          disabled={cancellingId === order._id}
                          className="px-4 py-2 text-sm font-medium text-red-600 border border-red-600 rounded-lg hover:bg-red-50 disabled:opacity-50 disabled:cursor-not-allowed transition duration-150"
                        >
                          {cancellingId === order._id ? 'Cancelling...' : 'Cancel Order'}
                        </button>
                      )}
                      <Link
                        to={`/orders/${order._id}`}
                        className="text-primary-600 hover:text-primary-700 font-medium text-sm"
                      >
                        View Details →
                      </Link>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default Orders;
