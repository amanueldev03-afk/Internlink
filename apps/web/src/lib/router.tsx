import { createBrowserRouter, Navigate } from 'react-router-dom';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <Navigate to="/dashboard" replace />,
  },
  {
    path: '/dashboard',
    element: <div className="p-8 text-slate-200">InternLink dashboard shell</div>,
  },
  {
    path: '/login',
    element: <div className="p-8 text-slate-200">Login page placeholder</div>,
  },
]);
