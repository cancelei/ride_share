# Prospera Storage - GitHub Pages Website

A professional, responsive website for Prospera Storage built with HTML, CSS, and JavaScript.

## 🚀 Quick Setup Guide

### Step 1: Create GitHub Account (if you don't have one)
1. Go to [github.com](https://github.com)
2. Click "Sign up"
3. Follow the registration process

### Step 2: Create a New Repository
1. Log in to GitHub
2. Click the "+" icon in the top right → "New repository"
3. Repository name: `prosperastorage` (or any name you prefer)
4. Description: "Prospera Storage website"
5. Make it **Public**
6. ✓ Check "Add a README file"
7. Click "Create repository"

### Step 3: Upload Your Website Files
1. In your new repository, click "Add file" → "Upload files"
2. Drag and drop these files:
   - `index.html`
   - `styles.css`
   - `script.js`
3. Scroll down and click "Commit changes"

### Step 4: Enable GitHub Pages
1. In your repository, click "Settings" (top menu)
2. Scroll down to "Pages" in the left sidebar
3. Under "Source", select "main" branch
4. Click "Save"
5. Wait 1-2 minutes for deployment

### Step 5: Access Your Website
Your website will be live at:
```
https://[your-username].github.io/prosperastorage/
```

For example, if your GitHub username is "johnsmith":
```
https://johnsmith.github.io/prosperastorage/
```

---

## 📝 Customization Checklist

Before going live, update these items:

### 1. Contact Information (in `index.html`)

**Line 253** - WhatsApp number:
```html
<a href="https://wa.me/1234567890?text=Hi!%20I'm%20interested%20in%20Prospera%20Go%20Storage." 
```
Replace `1234567890` with your actual WhatsApp number (include country code, no + or spaces)

**Line 255** - Email address:
```html
<a href="mailto:storage@prosperastorage.com">storage@prosperastorage.com</a>
```
Replace with your actual email

**Line 269** - Footer WhatsApp:
```html
<li>WhatsApp: <a href="https://wa.me/1234567890">+1 (234) 567-890</a></li>
```
Replace with your actual WhatsApp number

**Line 270** - Footer email:
```html
<li>Email: <a href="mailto:storage@prosperastorage.com">storage@prosperastorage.com</a></li>
```
Replace with your actual email

### 2. Optional Customizations

**Colors** (in `styles.css`, lines 13-15):
```css
--primary-color: #6366f1;  /* Main purple color */
--primary-dark: #4f46e5;   /* Darker purple for hover */
--secondary-color: #10b981; /* Green accent */
```

**Hero Text** (in `index.html`, lines 27-28):
```html
<h2>Smart Storage for Prospera Residents</h2>
<p class="hero-subtitle">Store your belongings securely while you travel...</p>
```

---

## 🔧 Advanced: Custom Domain (Optional)

If you want to use your own domain (e.g., `prosperagostorage.com`):

1. Buy a domain from Namecheap, GoDaddy, or Google Domains (~$15/year)
2. In your domain provider's DNS settings, add these records:
   ```
   Type: A
   Name: @
   Value: 185.199.108.153
   
   Type: A
   Name: @
   Value: 185.199.109.153
   
   Type: A
   Name: @
   Value: 185.199.110.153
   
   Type: A
   Name: @
   Value: 185.199.111.153
   
   Type: CNAME
   Name: www
   Value: [your-username].github.io
   ```
3. In your GitHub repository, go to Settings → Pages
4. Under "Custom domain", enter your domain
5. Click "Save"
6. Wait 24-48 hours for DNS propagation

---

## 📱 Mobile Responsive

The website is fully responsive and looks great on:
- Desktop computers
- Tablets
- Mobile phones

Test it by resizing your browser window or viewing on different devices.

---

## 🎨 Features

✓ Professional design matching Prospera Go style
✓ Responsive layout (mobile-friendly)
✓ Smooth scrolling navigation
✓ Pricing table with all box sizes
✓ FAQ section
✓ WhatsApp integration for easy booking
✓ Fast loading (no external dependencies)
✓ SEO-friendly structure

---

## 📊 What's Included

- **Hero Section**: Eye-catching introduction with call-to-action
- **Benefits**: Why choose Prospera Storage
- **How It Works**: 4-step process
- **Pricing Table**: All box sizes and durations
- **FAQ**: Common questions answered
- **Contact**: WhatsApp and email integration
- **Footer**: Quick links and contact info

---

## 🔄 Making Updates

To update your website after it's live:

1. Go to your GitHub repository
2. Click on the file you want to edit (e.g., `index.html`)
3. Click the pencil icon (Edit this file)
4. Make your changes
5. Scroll down and click "Commit changes"
6. Changes will be live in 1-2 minutes

---

## 💡 Tips

1. **Test WhatsApp Link**: Click the "Request Storage" button to make sure it opens WhatsApp correctly
2. **Check Email Link**: Click email links to ensure they open your email client
3. **Mobile Testing**: View the site on your phone to check mobile experience
4. **Share the Link**: Once live, share your GitHub Pages URL with customers

---

## 🆘 Troubleshooting

**Website not showing up?**
- Wait 2-3 minutes after enabling GitHub Pages
- Make sure repository is Public
- Check that files are in the root directory (not in a folder)
- Clear your browser cache (Ctrl+Shift+R or Cmd+Shift+R)

**WhatsApp link not working?**
- Make sure phone number includes country code
- Remove any spaces, dashes, or + symbols from the number
- Format: `https://wa.me/15041234567` (example for Honduras)

**Want to make changes?**
- Edit files directly on GitHub (click file → pencil icon)
- Or download files, edit locally, and re-upload

---

## 📈 Next Steps

After launching your website:

1. **Set up Stripe** for payment processing
2. **Create Google Sheet** for customer tracking
3. **Test the booking flow** with a friend
4. **Share the link** in Prospera Go community
5. **Monitor inquiries** via WhatsApp/email
6. **Gather feedback** and iterate

---

## 🎯 Cost

**GitHub Pages:** FREE  
**Domain (optional):** $15/year  
**Total:** $0-15/year

Compare to:
- Carrd: $19/year
- Webflow: $168/year
- Squarespace: $192/year

---

## 📞 Support

If you need help setting this up:
1. Check the troubleshooting section above
2. Google "GitHub Pages setup" for detailed guides
3. Ask in the Prospera community

---

**Ready to launch? Follow the Quick Setup Guide above!** 🚀

---

## 🌐 Custom Domain Setup

Your domain **prosperastorage.com** is ready to connect!

See **CUSTOM_DOMAIN_SETUP.md** for complete instructions on:
- Configuring Porkbun DNS
- Connecting to GitHub Pages
- Enabling HTTPS
- Testing your domain

**Your website will be live at:** https://prosperastorage.com

---

## 📧 Email Setup

Set up **hello@prosperastorage.com** for free!

See **EMAIL_SETUP.md** for instructions on:
- Free email forwarding with Porkbun
- Sending from your custom domain
- Upgrading to Google Workspace (optional)

