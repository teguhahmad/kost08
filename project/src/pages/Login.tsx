import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import Button from '../components/ui/Button';
import { Mail, Lock, AlertCircle, Building2, User } from 'lucide-react';

const Login: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isBackoffice, setIsBackoffice] = useState(false);

  const handleAuth = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      if (isLogin) {
        // Login
        const { data: { user }, error: signInError } = await supabase.auth.signInWithPassword({
          email,
          password
        });

        if (signInError) throw signInError;

        if (isBackoffice) {
          const { data: backofficeUser, error: backofficeError } = await supabase
            .from('backoffice_users')
            .select('*')
            .eq('email', email)
            .eq('status', 'active')
            .maybeSingle();

          if (backofficeError) throw backofficeError;
          
          if (!backofficeUser) {
            throw new Error('Unauthorized access to backoffice');
          }

          navigate('/backoffice');
        } else {
          const from = (location.state as any)?.from || '/properties';
          navigate(from);
        }
      } else {
        // Sign up
        const { data: { user }, error: signUpError } = await supabase.auth.signUp({
          email,
          password,
          options: {
            data: {
              name: name
            }
          }
        });

        if (signUpError) throw signUpError;

        // Create initial user settings
        const { error: settingsError } = await supabase
          .from('user_settings')
          .insert([{ user_id: user?.id }]);

        if (settingsError) throw settingsError;

        navigate('/properties');
      }
    } catch (err) {
      if (err instanceof Error) {
        setError(
          err.message === 'Unauthorized access to backoffice'
            ? 'Anda tidak memiliki akses ke backoffice'
            : err.message === 'Invalid login credentials'
            ? 'Email atau kata sandi salah'
            : err.message
        );
      } else {
        setError('Terjadi kesalahan');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <h1 className="text-3xl font-bold text-center text-blue-600 mb-2">
          KostManager
        </h1>
        <h2 className="mt-6 text-center text-2xl font-bold text-gray-900">
          {isBackoffice ? 'Backoffice Login' : (isLogin ? 'Masuk ke akun Anda' : 'Daftar akun baru')}
        </h2>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          {error && (
            <div className="mb-4 bg-red-50 border border-red-200 text-red-600 rounded-md p-4 flex items-start">
              <AlertCircle className="h-5 w-5 mr-2 mt-0.5" />
              <span>{error}</span>
            </div>
          )}

          <form className="space-y-6" onSubmit={handleAuth}>
            {!isLogin && (
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                  Nama Lengkap
                </label>
                <div className="mt-1 relative">
                  <input
                    id="name"
                    name="name"
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    className="appearance-none block w-full px-3 py-2 pl-10 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                  />
                  <User className="h-5 w-5 text-gray-400 absolute left-3 top-2.5" />
                </div>
              </div>
            )}

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                Email
              </label>
              <div className="mt-1 relative">
                <input
                  id="email"
                  name="email"
                  type="email"
                  autoComplete="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="appearance-none block w-full px-3 py-2 pl-10 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                />
                <Mail className="h-5 w-5 text-gray-400 absolute left-3 top-2.5" />
              </div>
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                Kata Sandi
              </label>
              <div className="mt-1 relative">
                <input
                  id="password"
                  name="password"
                  type="password"
                  autoComplete="current-password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="appearance-none block w-full px-3 py-2 pl-10 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                />
                <Lock className="h-5 w-5 text-gray-400 absolute left-3 top-2.5" />
              </div>
            </div>

            <div>
              <Button
                type="submit"
                className="w-full flex justify-center"
                disabled={loading}
              >
                {loading ? 'Memproses...' : (isLogin ? 'Masuk' : 'Daftar')}
              </Button>
            </div>
          </form>

          <div className="mt-6">
            <Button
              variant="outline"
              className="w-full flex justify-center items-center"
              onClick={() => {
                if (isBackoffice) {
                  setIsBackoffice(false);
                  setIsLogin(true);
                } else {
                  setIsLogin(!isLogin);
                }
              }}
              icon={isBackoffice ? <Building2 size={16} /> : undefined}
            >
              {isBackoffice ? 'Kembali ke Login User' : 
               (isLogin ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Masuk')}
            </Button>

            {!isBackoffice && isLogin && (
              <Button
                variant="outline"
                className="w-full flex justify-center items-center mt-2"
                onClick={() => setIsBackoffice(true)}
                icon={<Building2 size={16} />}
              >
                Login Backoffice
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;