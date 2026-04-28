const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/livechat';

const seedAdmin = async () => {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    const UserSchema = new mongoose.Schema({
      name: { type: String, required: true },
      email: { type: String, required: true, unique: true },
      password: { type: String, required: true },
      role: { type: String, default: 'agent' },
      status: { type: String, default: 'offline' }
    });

    const User = mongoose.models.User || mongoose.model('User', UserSchema);

    const email = 'admin@yourdomain.com';
    const password = 'supersecretpassword123!';

    const existingAdmin = await User.findOne({ email });

    if (existingAdmin) {
      console.log('Admin already exists!');
    } else {
      const hashedPassword = await bcrypt.hash(password, 10);
      const newAdmin = new User({
        name: 'Super Admin',
        email,
        password: hashedPassword,
        role: 'super_admin'
      });

      await newAdmin.save();
      console.log('Super Admin created successfully!');
      console.log('-------------------------');
      console.log(`Email: ${email}`);
      console.log(`Password: ${password}`);
      console.log('-------------------------');
      console.log('Please change the password after logging in.');
    }

  } catch (error) {
    console.error('Error seeding database:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
    process.exit(0);
  }
};

seedAdmin();
