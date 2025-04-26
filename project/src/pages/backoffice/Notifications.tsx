{/* Update the loadUsers function to use backoffice_users instead of auth.users */}
const loadUsers = async () => {
  try {
    const { data, error } = await supabase
      .from('backoffice_users')
      .select('user_id, role');
    if (error) throw error;
    setUsers(data || []);
  } catch (err) {
    console.error('Error loading users:', err);
  }
};

export default loadUsers