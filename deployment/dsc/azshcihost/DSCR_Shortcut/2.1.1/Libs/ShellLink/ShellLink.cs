using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
using System.Text;
using ComTypes = System.Runtime.InteropServices.ComTypes;

// Original code is https://emoacht.wordpress.com/2012/11/14/csharp-appusermodelid/
public class ShellLink : IDisposable
{
    #region Win32 and COM

    // IShellLink Interface
    [ComImport]
    [Guid("000214F9-0000-0000-C000-000000000046")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IShellLinkW
    {
        uint GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszFile, int cch, ref WIN32_FIND_DATAW pfd, uint fFlags);
        uint GetIDList(out IntPtr ppidl);
        uint SetIDList(IntPtr pidl);
        uint GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName, int cch);
        uint SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
        uint GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszDir, int cch);
        uint SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
        uint GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszArgs, int cch);
        uint SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
        uint GetHotKey(out ushort pwHotkey);
        uint SetHotKey(ushort wHotKey);
        uint GetShowCmd(out int piShowCmd);
        uint SetShowCmd(int iShowCmd);
        uint GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszIconPath, int cch, out int piIcon);
        uint SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
        uint SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, uint dwReserved);
        uint Resolve(IntPtr hwnd, uint fFlags);
        uint SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
    }

    // ShellLink CoClass (ShellLink object)
    [ComImport]
    [ClassInterface(ClassInterfaceType.None)]
    [Guid("00021401-0000-0000-C000-000000000046")]
    private class CShellLink { }

    // WIN32_FIND_DATAW Structure
    [StructLayout(LayoutKind.Sequential, Pack = 4, CharSet = CharSet.Unicode)]
    private struct WIN32_FIND_DATAW
    {
        public uint dwFileAttributes;
        public ComTypes.FILETIME ftCreationTime;
        public ComTypes.FILETIME ftLastAccessTime;
        public ComTypes.FILETIME ftLastWriteTime;
        public uint nFileSizeHigh;
        public uint nFileSizeLow;
        public uint dwReserved0;
        public uint dwReserved1;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = MAX_PATH)]
        public string cFileName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)]
        public string cAlternateFileName;
    }

    // IPropertyStore Interface
    [ComImport]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    [Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99")]
    private interface IPropertyStore
    {
        uint GetCount([Out] out uint cProps);
        uint GetAt([In] uint iProp, out PropertyKey pkey);
        uint GetValue([In] ref PropertyKey key, [Out] PropVariant pv);
        uint SetValue([In] ref PropertyKey key, [In] PropVariant pv);
        uint Commit();
    }

    // PropertyKey Structure
    // Narrowed down from PropertyKey.cs of Windows API Code Pack 1.1
    [StructLayout(LayoutKind.Sequential, Pack = 4)]
    private struct PropertyKey
    {
        #region Fields

        private Guid formatId; // Unique GUID for property
        private Int32 propertyId; // Property identifier (PID)

        #endregion

        #region Public Properties

        public Guid FormatId
        {
            get { return formatId; }
        }

        public Int32 PropertyId
        {
            get { return propertyId; }
        }

        #endregion

        #region Constructor

        public PropertyKey(Guid formatId, Int32 propertyId)
        {
            this.formatId = formatId;
            this.propertyId = propertyId;
        }

        public PropertyKey(string formatId, Int32 propertyId)
        {
            this.formatId = new Guid(formatId);
            this.propertyId = propertyId;
        }

        #endregion
    }

    // PropVariant Class (only for string value)
    // Narrowed down from PropVariant.cs of Windows API Code Pack 1.1
    // Originally from http://blogs.msdn.com/b/adamroot/archive/2008/04/11
    // /interop-with-propvariants-in-net.aspx
    [StructLayout(LayoutKind.Explicit)]
    private sealed class PropVariant : IDisposable
    {
        #region Fields

        [FieldOffset(0)]
        ushort valueType; // Value type

        // [FieldOffset(2)]
        // ushort wReserved1; // Reserved field
        // [FieldOffset(4)]
        // ushort wReserved2; // Reserved field
        // [FieldOffset(6)]
        // ushort wReserved3; // Reserved field

        [FieldOffset(8)]
        IntPtr ptr; // Value

        #endregion

        #region Public Properties

        // Value type (System.Runtime.InteropServices.VarEnum)
        public VarEnum VarType
        {
            get { return (VarEnum)valueType; }
            set { valueType = (ushort)value; }
        }

        // Whether value is empty or null
        public bool IsNullOrEmpty
        {
            get { return (valueType == (ushort)VarEnum.VT_EMPTY || valueType == (ushort)VarEnum.VT_NULL); }
        }

        // Value (only for string value)
        public string Value
        {
            get { return Marshal.PtrToStringUni(ptr); }
        }

        #endregion

        #region Constructor

        public PropVariant() { }

        // Construct with string value
        public PropVariant(string value)
        {
            if (value == null)
                throw new ArgumentException("Failed to set value.");

            valueType = (ushort)VarEnum.VT_LPWSTR;
            ptr = Marshal.StringToCoTaskMemUni(value);
        }

        #endregion

        #region Destructor

        ~PropVariant()
        {
            Dispose();
        }

        public void Dispose()
        {
            PropVariantClear(this);
            GC.SuppressFinalize(this);
        }

        #endregion
    }

    [DllImport("Ole32.dll", PreserveSig = false)]
    private static extern void PropVariantClear([In, Out] PropVariant pvar);

    [DllImport("Shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
    private static extern void SHGetNameFromIDList(IntPtr pidl, uint sigdnName, [Out, MarshalAs(UnmanagedType.LPTStr)] out string ppszName);

    [DllImport("Shell32.dll")]
    private static extern void ILFree(IntPtr pidl);

    #endregion

    #region Private

    private IShellLinkW shellLinkW = null;

    private bool readOnly = false;

    private readonly PropertyKey AppUserModelIDKey =
        new PropertyKey("{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}", 5);

    private const int MAX_PATH = 260;
    private const int INFOTIPSIZE = 1024;

    private const int SW_SHOWNORMAL = 1;
    private const int SW_SHOWMINIMIZED = 2;
    private const int SW_SHOWMAXIMIZED = 3;
    private const int SW_SHOWMINNOACTIVE = 7;

    private const int STGM_READ = 0x00000000;
    private const int STGM_READWRITE = 0x00000002;
    private const uint SLGP_UNCPRIORITY = 0x0002;
    private const uint SLGP_RAWPATH = 0x0004;

    private const uint SIGDN_DESKTOPABSOLUTEPARSING = 0x80028000;


    private IPersistFile PersistFile
    {
        get
        {
            IPersistFile PersistFile = (IPersistFile)shellLinkW;
            if (PersistFile == null)
                throw new COMException("Failed to create IPersistFile.");
            else
                return PersistFile;
        }
    }

    private IPropertyStore PropertyStore
    {
        get
        {
            IPropertyStore PropertyStore = (IPropertyStore)shellLinkW;
            if (PropertyStore == null)
                throw new COMException("Failed to create IPropertyStore.");
            else
                return PropertyStore;
        }
    }

    #endregion

    #region Public

    // Path of loaded shortcut file
    public string FilePath
    {
        get
        {
            string shortcutFile;
            PersistFile.GetCurFile(out shortcutFile);
            return shortcutFile;
        }
    }

    // Path of target file
    public string TargetPath
    {
        get
        {
            StringBuilder targetPath = new StringBuilder(MAX_PATH);
            WIN32_FIND_DATAW data = new WIN32_FIND_DATAW();

            VerifySucceeded(shellLinkW.GetPath(targetPath, targetPath.Capacity, ref data, SLGP_RAWPATH));
            return targetPath.ToString();
        }
        set
        {
            VerifyReadOnly();
            VerifySucceeded(shellLinkW.SetPath(value));
        }
    }

    // Shell item id list
    public string IDList
    {
        get
        {
            string idList;
            System.IntPtr pidl = IntPtr.Zero;

            try
            {
                VerifySucceeded(shellLinkW.GetIDList(out pidl));
                SHGetNameFromIDList(pidl, SIGDN_DESKTOPABSOLUTEPARSING, out idList);
                return idList;
            }
            finally
            {
                ILFree(pidl);
            }
        }
    }

    // Description
    public string Description
    {
        get
        {
            StringBuilder description = new StringBuilder(INFOTIPSIZE);

            VerifySucceeded(shellLinkW.GetDescription(description, description.Capacity));
            return description.ToString();
        }
        set
        {
            VerifyReadOnly();
            VerifySucceeded(shellLinkW.SetDescription(value));
        }
    }

    // Arguments
    public string Arguments
    {
        get
        {
            StringBuilder arguments = new StringBuilder(INFOTIPSIZE);

            VerifySucceeded(shellLinkW.GetArguments(arguments, arguments.Capacity));
            return arguments.ToString();
        }
        set
        {
            VerifyReadOnly();
            VerifySucceeded(shellLinkW.SetArguments(value));
        }
    }

    // WorkingDirectory
    public string WorkingDirectory
    {
        get
        {
            StringBuilder workingDirectory = new StringBuilder(MAX_PATH);

            VerifySucceeded(shellLinkW.GetWorkingDirectory(workingDirectory, workingDirectory.Capacity));
            return workingDirectory.ToString();
        }
        set
        {
            VerifyReadOnly();
            VerifySucceeded(shellLinkW.SetWorkingDirectory(value));
        }
    }

    // IconLocation
    public string IconLocation
    {
        get
        {
            StringBuilder iconLocation = new StringBuilder(MAX_PATH);
            int iconIdx;
            VerifySucceeded(shellLinkW.GetIconLocation(iconLocation, iconLocation.Capacity, out iconIdx));
            iconLocation.Append(",");
            iconLocation.Append(iconIdx.ToString());
            return iconLocation.ToString();
        }
        set
        {
            VerifyReadOnly();

            int idx = value.LastIndexOf(",");
            string iconLocation;
            string strIdx;
            int iconIdx;
            if (idx >= 0)
            {
                strIdx = value.Substring(idx + 1);
                if (Int32.TryParse(strIdx, out iconIdx))
                {
                    iconLocation = value.Substring(0, idx);
                }
                else
                {
                    iconLocation = value;
                    iconIdx = 0;
                }
            }
            else
            {
                iconLocation = value;
                iconIdx = 0;
            }
            VerifySucceeded(shellLinkW.SetIconLocation(iconLocation, iconIdx));
        }
    }

    // WindowStyle
    public int WindowStyle
    {
        get
        {
            int windowStyle;

            VerifySucceeded(shellLinkW.GetShowCmd(out windowStyle));
            switch (windowStyle)
            {
                case SW_SHOWMINIMIZED:
                case SW_SHOWMINNOACTIVE:
                    return SW_SHOWMINNOACTIVE;

                case SW_SHOWMAXIMIZED:
                    return SW_SHOWMAXIMIZED;

                case SW_SHOWNORMAL:
                    return SW_SHOWNORMAL;

                default:
                    return 0;
            }
        }
        set
        {
            VerifyReadOnly();

            int windowStyle;
            switch (value)
            {
                case 0:
                case 1:
                    windowStyle = SW_SHOWNORMAL;
                    break;

                case 3:
                    windowStyle = SW_SHOWMAXIMIZED;
                    break;

                case 7:
                    windowStyle = SW_SHOWMINNOACTIVE;
                    break;

                default:
                    throw new ArgumentException("Unsupported value.");
            }

            VerifySucceeded(shellLinkW.SetShowCmd(windowStyle));
        }
    }

    // Hotkey
    public ushort Hotkey
    {
        get
        {
            ushort hotKey;
            VerifySucceeded(shellLinkW.GetHotKey(out hotKey));
            return hotKey;
        }
        set
        {
            VerifyReadOnly();
            VerifySucceeded(shellLinkW.SetHotKey(value));
        }
    }

    // AppUserModelID
    // https://docs.microsoft.com/en-us/windows/win32/shell/appids
    public string AppUserModelID
    {
        get
        {
            using (PropVariant pv = new PropVariant())
            {
                VerifySucceeded(PropertyStore.GetValue(AppUserModelIDKey, pv));

                if (pv.Value == null)
                    return string.Empty;
                else
                    return pv.Value;
            }
        }
        set
        {
            VerifyReadOnly();
            using (PropVariant pv = new PropVariant(value))
            {
                VerifySucceeded(PropertyStore.SetValue(AppUserModelIDKey, pv));
                VerifySucceeded(PropertyStore.Commit());
            }
        }
    }

    #endregion

    #region Constructor

    public ShellLink() : this(null) { }

    // Construct with loading shortcut file.
    public ShellLink(string file)
    {
        try
        {
            shellLinkW = (IShellLinkW)new CShellLink();
        }
        catch
        {
            throw new COMException("Failed to create ShellLink object.");
        }

        if (file != null)
            Load(file);
    }

    #endregion

    #region Destructor

    ~ShellLink()
    {
        Dispose(false);
    }

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    protected virtual void Dispose(bool disposing)
    {
        if (shellLinkW != null)
        {
            // Release all references.
            Marshal.FinalReleaseComObject(shellLinkW);
            shellLinkW = null;
        }
    }

    #endregion

    #region Methods

    // Save shortcut file.
    public void Save()
    {
        VerifyReadOnly();

        string file = FilePath;
        if (file == null)
            throw new InvalidOperationException("File name is not given.");
        else
            Save(file);
    }

    public void Save(string file)
    {
        if (file == null)
        {
            throw new ArgumentNullException("File name is required.");
        }
        else
        {
            VerifyReadOnly();
            PersistFile.Save(file, true);
        }
    }

    // Load shortcut file.
    public void Load(string file)
    {
        Load(file, STGM_READWRITE);
    }

    public void Load(string file, int flags)
    {
        if (!File.Exists(file))
        {
            throw new FileNotFoundException("File is not found.", file);
        }
        else
        {
            PersistFile.Load(file, flags);
            if ((flags & 0x0000000f) == 0)
                readOnly = true;
        }
    }

    // Verify if operation succeeded.
    private static void VerifySucceeded(uint hresult)
    {
        if (hresult > 1)
            throw new InvalidOperationException("Failed with HRESULT: " +
                hresult.ToString("X"));
    }

    // Verify if operation as read only.
    private void VerifyReadOnly()
    {
        if (readOnly)
            throw new UnauthorizedAccessException("This object is read-only.");
    }

    #endregion
}
