import tkinter as tk
from tkinter import ttk
import tkinter.messagebox
import time
import json
import os
import sys # os was imported twice, removed one
import errno
import atexit
try:  # For Pillow (PIL)
    from PIL import ImageTk, Image
except ImportError:
    tkinter.messagebox.showwarning("وابستگی یافت نشد",
                                   "کتابخانه Pillow (PIL) یافت نشد.\n"
                                   "برخی از آیکون‌ها و تصاویر ممکن است نمایش داده نشوند.\n"
                                   "برای تجربه کامل، لطفاً Pillow را نصب کنید (pip install Pillow).")

LOCK_FILE = "gamenet_app.lock"

# --- Styling Constants ---
FONT_FAMILY = 'Vazirmatn'  # فونت فارسی مدرن (نیاز به نصب روی سیستم)
FONT_SIZE_NORMAL = 12      # بزرگ‌تر برای خوانایی بهتر
FONT_SIZE_MEDIUM = 14
FONT_SIZE_LARGE = 16
FONT_SIZE_XLARGE = 18

# --- Modern Dark Material Palette ---
COLOR_BACKGROUND = "#23272E"  # Dark background
COLOR_FRAME_BG = "#2C313A"    # Slightly lighter for frames
COLOR_TEXT = "#ECEFF1"         # Light text
COLOR_PRIMARY = "#1976D2"      # Material Blue
COLOR_ACCENT = "#43A047"       # Material Green
COLOR_DANGER = "#E53935"       # Material Red
COLOR_SUCCESS = "#00BFAE"      # Material Teal
COLOR_DISABLED_FG = "#757575"  # Gray
COLOR_BORDER = "#424242"       # Dark border

# Style Names
STYLE_MAIN_BUTTON = 'Main.TButton'
STYLE_ACCENT_BUTTON = 'Accent.TButton'
STYLE_ITEM_BUTTON = 'Item.TButton' # For +/- buttons

STYLE_NORMAL_LABEL = 'Normal.TLabel'
STYLE_HEADER_LABEL = 'Header.TLabel'
STYLE_SUBHEADER_LABEL = 'SubHeader.TLabel'
STYLE_TOTAL_LABEL = 'Total.TLabel'
STYLE_CREDIT_LABEL = 'Credit.TLabel'

STYLE_MAIN_FRAME = 'Main.TFrame'
STYLE_CONTENT_FRAME = 'Content.TFrame' # For frames holding content
STYLE_ACTIVE_DEVICE_FRAME = 'ActiveDevice.TFrame'


def is_process_running(pid_to_check):
    if not isinstance(pid_to_check, int) or pid_to_check <= 0:
        return False
    try:
        os.kill(pid_to_check, 0)
        return True
    except PermissionError:
        return True
    except OSError as e:
        if e.errno == errno.ESRCH:
            return False
        return False
    except Exception:
        return False

def cleanup_lock_file(lock_file_path, expected_pid):
    try:
        if os.path.exists(lock_file_path):
            pid_in_file_str = ""
            try:
                with open(lock_file_path, "r") as f:
                    pid_in_file_str = f.read().strip()
            except IOError:
                pass
            if pid_in_file_str == str(expected_pid):
                os.remove(lock_file_path)
    except Exception as e:
        print(f"خطا در حذف فایل قفل '{lock_file_path}' هنگام خروج: {e}")

def check_and_acquire_lock():
    current_pid = os.getpid()
    if os.path.exists(LOCK_FILE):
        try:
            with open(LOCK_FILE, "r") as f:
                pid_str = f.read().strip()
                if pid_str:
                    pid = int(pid_str)
                    if pid != current_pid and is_process_running(pid):
                        return False
        except (IOError, ValueError, TypeError) as e:
            print(f"خطا در خواندن فایل قفل یا PID نامعتبر: {e}. فرض بر این است که قفل قدیمی است.")
        except Exception as e:
            print(f"خطای غیرمنتظره در بررسی فایل قفل: {e}. فرض بر این است که قفل قدیمی است.")
    try:
        with open(LOCK_FILE, "w") as f:
            f.write(str(current_pid))
        atexit.register(cleanup_lock_file, LOCK_FILE, current_pid)
        return True
    except IOError as e:
        tkinter.messagebox.showerror("خطای فایل قفل", f"امکان ایجاد فایل قفل وجود ندارد: {e}\nبرنامه بسته می‌شود.")
        sys.exit(1)


class GameNetApp:
    NUM_PC_DEVICES = 8
    NUM_PS4_DEVICES = 4  # تعداد دستگاه‌های PS4
    DEVICES_PER_ROW = 4

    def __init__(self, master):
        self.master = master
        master.title("مدیریت گیم نت بزرگا") # Changed title
        master.geometry("1100x800") # Set a default size
        self.center_window()

        self._configure_styles()

        self.prices = self.load_prices()
        self.contacts = self.load_contacts()
        self.credits = self.load_credits()

        self.notebook = ttk.Notebook(self.master)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        self.device_frames = {}
        self.timer_frame = None # Will be set in create_timer_tab
        self.account_book_frame = None # Will be set in create_account_book_tab

        # Load icons once
        try:
            pc_icon_image = Image.open("pc_icon.png").resize((80, 80), Image.LANCZOS)
            self.pc_icon_tk = ImageTk.PhotoImage(pc_icon_image)
        except Exception as e:
            print(f"Error loading pc_icon.png: {e}")
            self.pc_icon_tk = None
        try:
            ps4_icon_image = Image.open("ps4.ico").resize((80, 80), Image.LANCZOS) # Assuming ps4.ico
            self.ps4_icon_tk = ImageTk.PhotoImage(ps4_icon_image)
        except Exception as e:
            print(f"Error loading ps4.ico: {e}")
            self.ps4_icon_tk = None

        self.create_timer_tab()
        self.create_account_book_tab()

        settings_button = ttk.Button(self.master, text="تنظیمات قیمت", command=self.open_settings, style=STYLE_MAIN_BUTTON)
        settings_button.pack(side=tk.TOP, anchor=tk.NE, padx=10, pady=(0,10)) # Adjusted padding

        self.master.protocol("WM_DELETE_WINDOW", self.on_close)

        self.credit_labels = {}
        self.device_timers = {}

        # self.master.rowconfigure(0, weight=1) # Not needed if notebook fills master
        # self.master.columnconfigure(0, weight=1)
        self.device_assignments = self.load_device_assignments()

        # self.ps4_timer_running = False # Removed for individual PS4 devices
        # self.ps4_start_time = 0 # Removed
        # self.ps4_timer_label = ttk.Label(self.master, text="00:00:00", font=(FONT_FAMILY, FONT_SIZE_NORMAL), style=STYLE_NORMAL_LABEL) # Removed
        # self.ps4_timer_data = {} # Not actively used, can be removed if not needed
        # self.create_ps4_logo() # Removed, PS4s are now part of device widgets
 
        self.notebook.bind("<<NotebookTabChanged>>", self.on_tab_changed)
        self.master.configure(bg=COLOR_BACKGROUND)


    def _configure_styles(self):
        self.style = ttk.Style()
        try:
            self.style.theme_use('clam')
        except tk.TclError:
            print("تم 'clam' در دسترس نیست، از تم پیش‌فرض استفاده می‌شود.")
            self.style.theme_use('default') # Fallback theme

        self.style.configure('.', font=(FONT_FAMILY, FONT_SIZE_NORMAL), background=COLOR_BACKGROUND, foreground=COLOR_TEXT)

        # --- Button Styles ---
        self.style.configure(STYLE_MAIN_BUTTON, padding=(8, 6), font=(FONT_FAMILY, FONT_SIZE_MEDIUM), relief="flat", borderwidth=1)
        self.style.map(STYLE_MAIN_BUTTON,
                       background=[('active', COLOR_ACCENT), ('!disabled', COLOR_PRIMARY)],
                       foreground=[('!disabled', 'white')],
                       bordercolor=[('focus', COLOR_ACCENT), ('!focus', COLOR_PRIMARY)])

        self.style.configure(STYLE_ACCENT_BUTTON, padding=(8, 6), font=(FONT_FAMILY, FONT_SIZE_MEDIUM), relief="flat", borderwidth=1)
        self.style.map(STYLE_ACCENT_BUTTON,
                       background=[('active', COLOR_PRIMARY), ('!disabled', COLOR_ACCENT)],
                       foreground=[('!disabled', 'white')],
                       bordercolor=[('focus', COLOR_PRIMARY), ('!focus', COLOR_ACCENT)])
        
        self.style.configure(STYLE_ITEM_BUTTON, padding=(2, 2), font=(FONT_FAMILY, FONT_SIZE_NORMAL), relief="flat", width=2)
        self.style.map(STYLE_ITEM_BUTTON,
                       background=[('active', COLOR_ACCENT), ('!disabled', COLOR_PRIMARY)],
                       foreground=[('!disabled', 'white')])


        # --- Label Styles ---
        self.style.configure(STYLE_NORMAL_LABEL, font=(FONT_FAMILY, FONT_SIZE_NORMAL), padding=(2, 2), background=COLOR_FRAME_BG)
        self.style.configure(STYLE_HEADER_LABEL, font=(FONT_FAMILY, FONT_SIZE_LARGE, 'bold'), padding=(5, 8), background=COLOR_FRAME_BG, foreground=COLOR_PRIMARY)
        self.style.configure(STYLE_SUBHEADER_LABEL, font=(FONT_FAMILY, FONT_SIZE_MEDIUM, 'bold'), padding=(3, 3), background=COLOR_FRAME_BG, foreground=COLOR_TEXT)
        self.style.configure(STYLE_TOTAL_LABEL, font=(FONT_FAMILY, FONT_SIZE_LARGE, 'bold'), padding=(5, 5), background=COLOR_FRAME_BG, foreground=COLOR_DANGER)
        self.style.configure(STYLE_CREDIT_LABEL, font=(FONT_FAMILY, FONT_SIZE_LARGE, 'bold'), padding=(5, 5), background=COLOR_FRAME_BG, foreground=COLOR_SUCCESS)

        # --- Frame Styles ---
        self.style.configure(STYLE_MAIN_FRAME, background=COLOR_BACKGROUND, padding=0) # Main tab frames
        self.style.configure(STYLE_CONTENT_FRAME, background=COLOR_FRAME_BG, padding=10, relief="solid", borderwidth=1, bordercolor=COLOR_BORDER)
        self.style.configure(STYLE_ACTIVE_DEVICE_FRAME, background=COLOR_SUCCESS, padding=10, relief="solid", borderwidth=1, bordercolor=COLOR_BORDER)


        # --- Notebook Styles ---
        self.style.configure('TNotebook', background=COLOR_BACKGROUND, tabmargins=[2, 5, 2, 0], borderwidth=0)
        self.style.configure('TNotebook.Tab', font=(FONT_FAMILY, FONT_SIZE_MEDIUM), padding=[15, 8], relief="flat")
        self.style.map('TNotebook.Tab',
                       background=[('selected', COLOR_PRIMARY), ('active', COLOR_ACCENT), ('!selected', COLOR_FRAME_BG)],
                       foreground=[('selected', 'white'), ('active', 'white'), ('!selected', COLOR_TEXT)],
                       borderwidth=[('selected', 1)],
                       bordercolor=[('selected', COLOR_PRIMARY)])
        
        # --- Treeview Style ---
        self.style.configure('Treeview', font=(FONT_FAMILY, FONT_SIZE_MEDIUM), rowheight=36, background=COLOR_FRAME_BG, fieldbackground=COLOR_FRAME_BG)
        self.style.configure('Treeview.Heading', font=(FONT_FAMILY, FONT_SIZE_LARGE, 'bold'), padding=(8,12), background=COLOR_PRIMARY, foreground='white', relief="flat")
        self.style.map('Treeview.Heading', relief=[('active', 'groove'), ('!active', 'flat')])
        self.style.layout("Treeview", [('Treeview.treearea', {'sticky': 'nswe'})]) # Remove borders from treearea itself

        # --- Entry Style ---
        self.style.configure('TEntry', font=(FONT_FAMILY, FONT_SIZE_NORMAL), padding=5, relief="solid", borderwidth=1, bordercolor=COLOR_BORDER,
                            fieldbackground=COLOR_FRAME_BG, foreground=COLOR_TEXT, insertcolor=COLOR_TEXT)
        self.style.map('TEntry', bordercolor=[('focus', COLOR_PRIMARY)])


    def center_toplevel_window(self, window, width=350, height=250): # Adjusted default size
        window.update_idletasks()
        # Use reqwidth/reqheight if window size is dynamic, else use provided width/height
        win_width = window.winfo_reqwidth() if width is None else width
        win_height = window.winfo_reqheight() if height is None else height
        
        screen_width = window.winfo_screenwidth()
        screen_height = window.winfo_screenheight()

        x = (screen_width - win_width) // 2
        y = (screen_height - win_height) // 2
        window.geometry(f"{win_width}x{win_height}+{x}+{y}")
        window.configure(bg=COLOR_FRAME_BG) # Style Toplevel background


    def on_tab_changed(self, event):
        current_tab_widget = self.notebook.nametowidget(self.notebook.select())

        # # Handle PS4 logo visibility - Removed as PS4s are now individual devices
        # if hasattr(self, 'ps4_logo_label') and self.ps4_logo_label.winfo_exists():
        #     if current_tab_widget == self.timer_frame:
        #         self.ps4_logo_label.place(in_=self.timer_frame, relx=0.8, rely=0.5, anchor="center")
        #         if self.ps4_timer_running: # This attribute is removed
        #             self.ps4_timer_label.place(in_=self.timer_frame, relx=0.8, rely=0.65, anchor="center")
        #         else:
        #             self.ps4_timer_label.place_forget()
        #     else:
        #         self.ps4_logo_label.place_forget()
        #         self.ps4_timer_label.place_forget()

        # Handle contact list deselection and details clearing
        if hasattr(self, 'contact_treeview') and self.contact_treeview.winfo_exists() and hasattr(self, 'contact_details_frame') and self.contact_details_frame.winfo_exists():
            if current_tab_widget != self.account_book_frame:
                selection = self.contact_treeview.selection()
                if selection:
                    self.contact_treeview.selection_remove(selection)
                for widget in self.contact_details_frame.winfo_children():
                    widget.destroy()
            # else: # Optionally, auto-select first contact if switching TO account tab and none selected
            #     if not self.contact_treeview.selection():
            #         children = self.contact_treeview.get_children()
            #         if children:
            #             self.contact_treeview.selection_set(children[0])
            #             self.contact_treeview.focus(children[0]) # Also focus
            #             self.show_contact_details()


    def load_device_assignments(self):
        try:
            with open("device_assignments.json", "r", encoding='utf-8') as f: # Added encoding
                return json.load(f)
        except FileNotFoundError:
            return {}
        except json.JSONDecodeError:
            print("خطا در خواندن device_assignments.json")
            return {}


    def save_device_assignments(self):
        with open("device_assignments.json", "w", encoding='utf-8') as f: # Added encoding
            json.dump(self.device_assignments, f, ensure_ascii=False, indent=4)


    def center_window(self):
        self.master.update_idletasks()
        # For main window, better to set initial size then center
        width = self.master.winfo_width()
        height = self.master.winfo_height()
        screen_width = self.master.winfo_screenwidth()
        screen_height = self.master.winfo_screenheight()
        x = (screen_width // 2) - (width // 2)
        y = (screen_height // 2) - (height // 2)
        self.master.geometry(f'{width}x{height}+{x}+{y}')


    def load_prices(self):
        try:
            with open("prices.json", "r", encoding='utf-8') as f: # Added encoding
                prices = json.load(f)
            default_prices = {"بازی": 10000, "کیک": 20000, "نوشابه": 20000, "هایپ": 30000, "PC": 850, "PS4": 850}
            for key, value in default_prices.items():
                prices.setdefault(key, value) # Use setdefault for cleaner update
        except (FileNotFoundError, json.JSONDecodeError):
            prices = {"بازی": 10000, "کیک": 20000, "نوشابه": 20000, "هایپ": 30000, "PC": 850, "PS4": 850}
        return prices

    def save_prices(self):
        with open("prices.json", "w", encoding='utf-8') as f: # Added encoding
            json.dump(self.prices, f, ensure_ascii=False, indent=4)

    def load_contacts(self):
        try:
            with open("contacts.json", "r", encoding='utf-8') as f: # Added encoding
                content = f.read()
                if not content.strip():
                    return {}
                return json.loads(content)
        except FileNotFoundError:
            return {}
        except json.JSONDecodeError:
            print("خطا در خواندن فایل contacts.json. فایل باید حاوی JSON معتبر باشد.")
            return {}

    def save_contacts(self):
        with open("contacts.json", "w", encoding='utf-8') as f: # Added encoding
            json.dump(self.contacts, f, ensure_ascii=False, indent=4)

    def create_timer_tab(self):
        self.timer_frame = ttk.Frame(self.notebook, style=STYLE_MAIN_FRAME)
        self.notebook.add(self.timer_frame, text="میز بازی")

        main_container = ttk.Frame(self.timer_frame, style=STYLE_MAIN_FRAME)
        main_container.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        devices_frame = ttk.Frame(main_container, style=STYLE_MAIN_FRAME)
        devices_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(0,10))

        flags_frame = ttk.Frame(main_container, style=STYLE_CONTENT_FRAME, width=250) # Give it a style
        flags_frame.pack(side=tk.RIGHT, fill=tk.Y, padx=(10,0))
        flags_frame.pack_propagate(False) # Prevent shrinking

        # Create rows for devices
        row_frames = []
        num_total_device_rows = ( (self.NUM_PC_DEVICES + self.DEVICES_PER_ROW -1) // self.DEVICES_PER_ROW +
                                  (self.NUM_PS4_DEVICES + self.DEVICES_PER_ROW -1) // self.DEVICES_PER_ROW )

        for i in range(num_total_device_rows):
            row_f = ttk.Frame(devices_frame, style=STYLE_MAIN_FRAME)
            row_f.pack(side=tk.TOP, pady=5, anchor='w', fill=tk.X, expand=True)
            devices_frame.grid_rowconfigure(i, weight=1)
            for col_idx in range(self.DEVICES_PER_ROW):
                row_f.grid_columnconfigure(col_idx, weight=1)
            row_frames.append(row_f)

        current_global_idx = 0
        # Populate PC devices
        num_pc_rows = (self.NUM_PC_DEVICES + self.DEVICES_PER_ROW - 1) // self.DEVICES_PER_ROW
        for i in range(self.NUM_PC_DEVICES):
            target_row_index = i // self.DEVICES_PER_ROW
            col_in_row = i % self.DEVICES_PER_ROW
            self.create_timer_widget(row_frames[target_row_index], current_global_idx, "PC", col_in_row)
            current_global_idx += 1

        # Populate PS4 devices
        for i in range(self.NUM_PS4_DEVICES):
            target_row_index = (i // self.DEVICES_PER_ROW) + num_pc_rows
            col_in_row = i % self.DEVICES_PER_ROW
            self.create_timer_widget(row_frames[target_row_index], current_global_idx, "PS4", col_in_row)
            current_global_idx +=1

        self.create_flags(flags_frame)

    def create_timer_widget(self, parent_row_frame, global_device_index, device_type, column_in_row):
        # Using STYLE_CONTENT_FRAME for individual device frames for border and bg
        frame = ttk.Frame(parent_row_frame, style=STYLE_CONTENT_FRAME)
        # Use grid within parent_frame for even distribution
        frame.grid(row=0, column=column_in_row, padx=10, pady=10, sticky="nsew")
        # parent_row_frame.grid_columnconfigure(column_in_row, weight=1) # Already configured in create_timer_tab

        click_handler = lambda event, idx=global_device_index: self.handle_device_click(idx)
        frame.bind("<Button-1>", click_handler)

        self.device_frames[global_device_index] = frame
        frame.device_type = device_type # Store device type on the frame

        icon_to_display = None
        if device_type == "PC":
            icon_to_display = self.pc_icon_tk
        elif device_type == "PS4":
            icon_to_display = self.ps4_icon_tk

        try:
            # This structure assumes icon_to_display is a valid PhotoImage or None

            # Vertical frame inside for content, ensure it uses the parent's bg
            vertical_frame = ttk.Frame(frame, style=STYLE_CONTENT_FRAME) # Match style
            vertical_frame.pack(pady=5, padx=5, fill=tk.BOTH, expand=True)
            vertical_frame.bind("<Button-1>", click_handler)
            
            icon_label = ttk.Label(vertical_frame, image=icon_to_display, style=STYLE_NORMAL_LABEL)
            if icon_to_display: # Keep reference if image exists
                icon_label.image = icon_to_display
            icon_label.pack(side=tk.TOP, pady=(0,5))
            icon_label.bind("<Button-1>", click_handler)

            if device_type == "PC":
                if global_device_index < self.DEVICES_PER_ROW: # First row of PCs
                    device_name_text = f"R{global_device_index + 1}"
                else: # Second row of PCs (assuming 2 PC rows for R/L naming)
                    device_name_text = f"L{(global_device_index % self.DEVICES_PER_ROW) + 1}"
            elif device_type == "PS4":
                ps4_order_index = global_device_index - self.NUM_PC_DEVICES # 0-based index among PS4s
                device_name_text = f"PS{ps4_order_index + 1}"
            else:
                device_name_text = f"دستگاه {global_device_index + 1}"

            device_label = ttk.Label(vertical_frame, text=device_name_text, style=STYLE_SUBHEADER_LABEL, anchor='center')
            device_label.pack(side=tk.TOP, pady=2, fill=tk.X)
            device_label.bind("<Button-1>", click_handler)

            timer_label = ttk.Label(vertical_frame, text="00:00:00", font=(FONT_FAMILY, FONT_SIZE_NORMAL), style=STYLE_NORMAL_LABEL, anchor='center')
            timer_label.pack(side=tk.BOTTOM, pady=(5,0), fill=tk.X)
            timer_label.pack_forget() # Initially hide
            timer_label.bind("<Button-1>", click_handler)

            frame.timer_label = timer_label
            frame.device_label = device_label # Store for potential style changes

        except Exception as e:
            print(f"Error creating widget for device {global_device_index} ({device_type}): {e}")
            # Fallback text if icon fails
            fallback_label = ttk.Label(frame, text=f"{device_type} {global_device_index+1}", style=STYLE_NORMAL_LABEL)
            fallback_label.pack(padx=10,pady=10)
            fallback_label.bind("<Button-1>", click_handler)
            
            fb_timer_label = ttk.Label(frame, text="00:00:00", font=(FONT_FAMILY, FONT_SIZE_NORMAL), style=STYLE_NORMAL_LABEL)
            fb_timer_label.pack_forget()
            fb_timer_label.bind("<Button-1>", click_handler)
            frame.timer_label = fb_timer_label


    def handle_device_click(self, index):
        device_frame = self.device_frames[index]
        device_type = device_frame.device_type

        if index not in self.device_timers:
            self.device_timers[index] = {"start_time": time.time(), "running": True, 
                                         "timer_label": device_frame.timer_label, "device_type": device_type}
            device_frame.timer_label.pack(side=tk.BOTTOM, pady=(5,0), fill=tk.X) # Ensure it's packed correctly
            self.update_device_timer(index)
            device_frame.configure(style=STYLE_ACTIVE_DEVICE_FRAME)
            for child in device_frame.winfo_children(): # Target inner frame
                if isinstance(child, ttk.Frame):
                    for grandchild in child.winfo_children():
                        if isinstance(grandchild, ttk.Label):
                            grandchild.configure(background=self.style.lookup(STYLE_ACTIVE_DEVICE_FRAME, 'background'))
        else:
            if self.device_timers[index]["running"]:
                if tkinter.messagebox.askyesno("تایید", "آیا بازی تمام شده است؟", parent=self.master):
                    self.device_timers[index]["running"] = False
                    elapsed_time = time.time() - self.device_timers[index]["start_time"]
                    minutes = int(elapsed_time // 60)
                    total_price = minutes * self.prices[device_type]
                    self.show_device_result(minutes, total_price, index, device_type)
                    device_frame.configure(style=STYLE_CONTENT_FRAME) # Revert style
                    for child in device_frame.winfo_children(): # Target inner frame
                        if isinstance(child, ttk.Frame):
                            for grandchild in child.winfo_children():
                                if isinstance(grandchild, ttk.Label):
                                     grandchild.configure(background=self.style.lookup(STYLE_CONTENT_FRAME, 'background'))
            else: # Restart timer
                self.device_timers[index]["running"] = True
                self.device_timers[index]["start_time"] = time.time() # Reset start time
                device_frame.timer_label.pack(side=tk.BOTTOM, pady=(5,0), fill=tk.X)
                self.update_device_timer(index)
                device_frame.configure(style=STYLE_ACTIVE_DEVICE_FRAME)
                for child in device_frame.winfo_children(): # Target inner frame
                    if isinstance(child, ttk.Frame):
                        for grandchild in child.winfo_children():
                            if isinstance(grandchild, ttk.Label):
                                grandchild.configure(background=self.style.lookup(STYLE_ACTIVE_DEVICE_FRAME, 'background'))


    def update_device_timer(self, index):
        if index in self.device_timers and self.device_timers[index]["running"]:
            elapsed_time = time.time() - self.device_timers[index]["start_time"]
            hours, remainder = divmod(int(elapsed_time), 3600)
            minutes, seconds = divmod(remainder, 60)
            time_str = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
            self.device_timers[index]["timer_label"].config(text=time_str)
            self.master.after(1000, self.update_device_timer, index)

    def show_device_result(self, minutes, total_price, index, device_type):
        result_window = tk.Toplevel(self.master)
        result_window.title(f"نتیجه بازی {device_type}")
        result_window.transient(self.master) # Make it transient
        result_window.grab_set() # Grab focus
        self.center_toplevel_window(result_window, width=350, height=220)

        container = ttk.Frame(result_window, style=STYLE_CONTENT_FRAME, padding=20)
        container.pack(fill=tk.BOTH, expand=True)
        ttk.Label(container, text=f"زمان بازی {device_type}: {minutes} دقیقه", style=STYLE_SUBHEADER_LABEL).pack(pady=5)
        ttk.Label(container, text=f"مبلغ قابل پرداخت: {total_price:,.0f} تومان", style=STYLE_SUBHEADER_LABEL).pack(pady=5) # Format price

        btn_frame = ttk.Frame(container, style=STYLE_CONTENT_FRAME) # Match style
        btn_frame.pack(pady=15)

        def paid_action():
            result_window.destroy()
            self.device_timers[index]["timer_label"].pack_forget()
            del self.device_timers[index]
            # Style revert is handled in handle_device_click

        def add_to_account_action():
            result_window.destroy()
            self.device_timers[index]["timer_label"].pack_forget()
            del self.device_timers[index]
            self.show_user_selection_for_payment(total_price, device_type)
            # Style revert is handled in handle_device_click

        ttk.Button(btn_frame, text="پرداخت شد", command=paid_action, style=STYLE_ACCENT_BUTTON).pack(side=tk.LEFT, padx=10)
        ttk.Button(btn_frame, text="حساب دفتری", command=add_to_account_action, style=STYLE_MAIN_BUTTON).pack(side=tk.RIGHT, padx=10)
        result_window.protocol("WM_DELETE_WINDOW", paid_action) # Default to paid if closed


    def show_user_selection_for_payment(self, total_price, device_type="PC"): # Added device_type
        selection_window = tk.Toplevel(self.master)
        selection_window.title(f"انتخاب کاربر برای حساب دفتری ({device_type})")
        selection_window.transient(self.master)
        selection_window.grab_set()
        self.center_toplevel_window(selection_window, width=350, height=400)

        container = ttk.Frame(selection_window, style=STYLE_CONTENT_FRAME, padding=15)
        container.pack(fill=tk.BOTH, expand=True)

        ttk.Label(container, text="یک کاربر را انتخاب کنید:", style=STYLE_SUBHEADER_LABEL).pack(pady=(0,5))

        # --- Search Bar for Selection Window ---
        search_frame = ttk.Frame(container, style=STYLE_CONTENT_FRAME) # Match style
        search_frame.pack(fill=tk.X, pady=(5,5))
        
        ttk.Label(search_frame, text="جستجو:", style=STYLE_SUBHEADER_LABEL).pack(side=tk.LEFT, padx=(0,5))
        # Use instance variables for search in this window
        selection_window.search_var = tk.StringVar()
        selection_window.search_entry = ttk.Entry(search_frame, textvariable=selection_window.search_var, font=(FONT_FAMILY, FONT_SIZE_NORMAL))
        selection_window.search_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        selection_window.search_entry.focus_set() # Set focus to search entry

        
        listbox_frame = ttk.Frame(container, style=STYLE_CONTENT_FRAME) # Frame for listbox with border
        listbox_frame.pack(fill=tk.BOTH, expand=True, pady=5)
        
        listbox = tk.Listbox(listbox_frame, font=(FONT_FAMILY, FONT_SIZE_NORMAL), relief="flat", borderwidth=0,
                             selectbackground=COLOR_PRIMARY, selectforeground="white", activestyle="none", exportselection=False)
        listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        scrollbar = ttk.Scrollbar(listbox_frame, orient=tk.VERTICAL, command=listbox.yview)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        listbox.config(yscrollcommand=scrollbar.set)

        # Method to populate the listbox (local to this function)
        def populate_listbox(filter_text=None):
            listbox.delete(0, tk.END) # Clear current items
            contacts_to_display = sorted(self.contacts.keys())
            if filter_text:
                contacts_to_display = [name for name in contacts_to_display if filter_text.lower() in name.lower()]
            
            for user in contacts_to_display:
                listbox.insert(tk.END, user)

        # Bind search entry to populate_listbox
        selection_window.search_var.trace_add("write", lambda *args: populate_listbox(selection_window.search_var.get()))

        # Add double-click event to listbox
        def on_listbox_double_click(event):
            # Check if there's a selection first, then confirm
            if listbox.curselection():
                confirm_user()
        listbox.bind("<Double-Button-1>", on_listbox_double_click)

        def confirm_user():
            selected_user_index = listbox.curselection()
            if selected_user_index:
                selected_user = listbox.get(selected_user_index[0])
                if selected_user in self.contacts:
                    # Ensure the device_type key exists for the user
                    self.contacts[selected_user].setdefault(device_type, 0)
                    self.contacts[selected_user][device_type] += int(total_price / self.prices[device_type])
                    self.save_contacts()
                    # If account book tab is active, refresh it
                    if self.notebook.tab(self.notebook.select(), "text") == "دفتر حساب":
                         current_selection = self.contact_treeview.selection()
                         if current_selection and self.contact_treeview.item(current_selection[0], "text") == selected_user:
                            self.show_contact_details() # Refresh if selected user is shown
                    selection_window.destroy()
                else:
                    tkinter.messagebox.showerror("خطا", "کاربر انتخاب شده در لیست مخاطبین وجود ندارد.", parent=selection_window)
            else:
                tkinter.messagebox.showwarning("هشدار", "لطفاً یک کاربر را انتخاب کنید.", parent=selection_window)

        # Initial population
        populate_listbox()

        ttk.Button(container, text="تایید", command=confirm_user, style=STYLE_ACCENT_BUTTON).pack(pady=(10,0))
        selection_window.protocol("WM_DELETE_WINDOW", selection_window.destroy)


    def create_flags(self, parent_frame):
        try:
            flag_image_pil = Image.open("Designer.png")
            flag_size = (60, 60) # Slightly smaller for flags section
            flag_image_pil = flag_image_pil.resize(flag_size, Image.LANCZOS)

            self.flag_icons = {
                color: {
                    "normal": ImageTk.PhotoImage(flag_image_pil),
                    "busy": ImageTk.PhotoImage(flag_image_pil.convert("LA").convert("RGB")) # Grayscale then back to RGB for PhotoImage
                } for color in ["red", "blue", "green", "yellow"]
            }
        except Exception as e:
            print(f"Error loading flag icons: {e}")
            self.flag_icons = {} # Ensure it exists
            return

        groups = [("گروه قرمز", "red"), ("گروه آبی", "blue"), ("گروه سبز", "green"), ("گروه زرد", "yellow")]
        
        parent_frame.configure(style=STYLE_CONTENT_FRAME) # Style the main flags_frame

        self.flag_states = { color: {"status": "normal", "timer": 0, "timer_label": None, "visible": False, "icon_label": None}
            for _, color in groups
        }
        
        # Use grid for flags for better alignment within their narrow column
        parent_frame.grid_columnconfigure(0, weight=1) # Single column

        for i, (name, color) in enumerate(groups):
            flag_group_frame = ttk.Frame(parent_frame, style=STYLE_CONTENT_FRAME) # Individual frame for each flag
            flag_group_frame.grid(row=i, column=0, pady=10, padx=5, sticky="ew")
            flag_group_frame.grid_columnconfigure(0, weight=1) # Center content

            icon_label = ttk.Label(flag_group_frame, image=self.flag_icons.get(color, {}).get("normal"), style=STYLE_NORMAL_LABEL)
            if icon_label.cget("image"): # Check if image was loaded
                icon_label.image = self.flag_icons[color]["normal"]
            icon_label.grid(row=0, column=0, pady=(0,5))
            icon_label.bind("<Button-1>", lambda e, c=color: self.handle_flag_click(c))
            self.flag_states[color]["icon_label"] = icon_label

            timer_label = ttk.Label(flag_group_frame, text="00:00:00", font=(FONT_FAMILY, FONT_SIZE_NORMAL-1), style=STYLE_NORMAL_LABEL)
            timer_label.grid(row=1, column=0)
            self.flag_states[color]["timer_label"] = timer_label
            timer_label.grid_remove() # Hide initially

            group_name_label = ttk.Label(flag_group_frame, text=name, font=(FONT_FAMILY, FONT_SIZE_NORMAL, 'bold'), style=STYLE_SUBHEADER_LABEL)
            group_name_label.grid(row=2, column=0, pady=(2,0))

    # Removed: create_ps4_logo, handle_ps4_click (global), update_ps4_timer (global), show_ps4_result (global)
    # These are now handled by the generic device timer widgets.


    def handle_flag_click(self, color):
        state = self.flag_states[color]
        icon_label_widget = state["icon_label"]

        if state["status"] == "normal":
            state["status"] = "busy"
            state["timer"] = 0
            state["visible"] = True
            state["timer_label"].grid() # Show timer
            self.update_flag_timer(color)
            if icon_label_widget and self.flag_icons.get(color):
                icon_label_widget.config(image=self.flag_icons[color]["busy"])
        else: # status is "busy"
            self.blink_and_hide_flag_timer(color) # This will also call show_losers_selection


    def blink_and_hide_flag_timer(self, color, count=0): # Modified for iterative blinking
        state = self.flag_states[color]
        label = state["timer_label"]
        icon_label_widget = state["icon_label"]

        if count < 6: # 3 blinks (on/off = 2 steps per blink * 3 = 6)
            current_fg = label.cget("foreground")
            new_fg = COLOR_DANGER if current_fg != COLOR_DANGER else self.style.lookup(STYLE_NORMAL_LABEL, 'foreground')
            label.config(foreground=new_fg)
            self.master.after(200, self.blink_and_hide_flag_timer, color, count + 1)
        else:
            label.grid_remove() # Hide timer
            label.config(foreground=self.style.lookup(STYLE_NORMAL_LABEL, 'foreground')) # Reset color
            if icon_label_widget and self.flag_icons.get(color):
                icon_label_widget.config(image=self.flag_icons[color]["normal"])
            
            state["status"] = "normal" # Reset status before showing losers
            state["timer"] = 0
            state["visible"] = False
            state["timer_label"].config(text="00:00:00")
            self.show_losers_selection(color)


    def update_flag_timer(self, color):
        state = self.flag_states[color]
        if state["status"] == "busy":
            state["timer"] += 1
            h, rem = divmod(state["timer"], 3600)
            m, s = divmod(rem, 60)
            time_str = f"{h:02d}:{m:02d}:{s:02d}"
            if state["visible"]:
                state["timer_label"].config(text=time_str)
            self.master.after(1000, self.update_flag_timer, color)


    def show_losers_selection(self, color):
        selection_window = tk.Toplevel(self.master)
        selection_window.title("انتخاب بازندگان")
        selection_window.transient(self.master)
        selection_window.grab_set()
        self.center_toplevel_window(selection_window, width=350, height=400)

        container = ttk.Frame(selection_window, style=STYLE_CONTENT_FRAME, padding=15)
        container.pack(fill=tk.BOTH, expand=True)

        ttk.Label(container, text="بازندگان را انتخاب کنید:", style=STYLE_SUBHEADER_LABEL).pack(pady=(0,5))

        # --- Search Bar for Losers Selection Window ---
        search_frame_losers = ttk.Frame(container, style=STYLE_CONTENT_FRAME)
        search_frame_losers.pack(fill=tk.X, pady=(5,5))
        
        ttk.Label(search_frame_losers, text="جستجو:", style=STYLE_SUBHEADER_LABEL).pack(side=tk.LEFT, padx=(0,5))
        search_var_losers = tk.StringVar()
        search_entry_losers = ttk.Entry(search_frame_losers, textvariable=search_var_losers, font=(FONT_FAMILY, FONT_SIZE_NORMAL))
        search_entry_losers.pack(side=tk.LEFT, fill=tk.X, expand=True)
        search_entry_losers.focus_set()


        if not self.contacts:
            tkinter.messagebox.showwarning("هشدار", "هیچ مخاطبی برای انتخاب وجود ندارد!", parent=selection_window)
            selection_window.destroy()
            return

        listbox_frame = ttk.Frame(container, style=STYLE_CONTENT_FRAME)
        listbox_frame.pack(fill=tk.BOTH, expand=True, pady=5)
        
        listbox = tk.Listbox(listbox_frame, selectmode=tk.MULTIPLE, font=(FONT_FAMILY, FONT_SIZE_NORMAL),
                             relief="flat", borderwidth=0, exportselection=False,
                             selectbackground=COLOR_PRIMARY, selectforeground="white", activestyle="none")
        listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        
        scrollbar = ttk.Scrollbar(listbox_frame, orient=tk.VERTICAL, command=listbox.yview)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        listbox.config(yscrollcommand=scrollbar.set)

        globally_selected_names = set() # To store names of all selected users, persisting across filters

        def populate_losers_listbox(filter_text=None):
            listbox.delete(0, tk.END) # Clear current items
            
            contacts_to_display = sorted(self.contacts.keys())
            if filter_text:
                contacts_to_display = [name for name in contacts_to_display if filter_text.lower() in name.lower()]
            
            for idx, user_name in enumerate(contacts_to_display):
                listbox.insert(tk.END, user_name)
                if user_name in globally_selected_names:
                    listbox.selection_set(idx)

        def handle_losers_listbox_selection_change(event):
            # Get currently selected items in the UI
            current_selection_indices = listbox.curselection()
            ui_selected_names = {listbox.get(i) for i in current_selection_indices}

            # Get all items currently visible in the listbox
            all_visible_names_in_listbox = {listbox.get(i) for i in range(listbox.size())}

            # Add newly selected visible items to the global set
            globally_selected_names.update(ui_selected_names)

            # Remove items that are visible but no longer selected in UI from the global set
            deselected_visible_items = all_visible_names_in_listbox - ui_selected_names
            globally_selected_names.difference_update(deselected_visible_items)

        # Initial population
        populate_losers_listbox()

        # Bind search entry to populate_losers_listbox
        search_var_losers.trace_add("write", lambda *args: populate_losers_listbox(search_var_losers.get()))
        listbox.bind("<<ListboxSelect>>", handle_losers_listbox_selection_change)


        btn_frame = ttk.Frame(container, style=STYLE_CONTENT_FRAME) # Match style
        btn_frame.pack(pady=(15,0), fill=tk.X)
        btn_frame.grid_columnconfigure(0, weight=1)
        btn_frame.grid_columnconfigure(1, weight=1)

        def confirm_action():
            # Use the globally_selected_names set which persists across filters
            if not globally_selected_names:
                tkinter.messagebox.showwarning("هشدار", "هیچ بازنده‌ای انتخاب نشده است.", parent=selection_window)
                return

            for loser_name in globally_selected_names:
                if loser_name in self.contacts:
                    self.contacts[loser_name].setdefault("بازی", 0) # Ensure 'بازی' key exists
                    self.contacts[loser_name]["بازی"] += 1
                else:
                    print(f"خطا: کاربر {loser_name} در لیست مخاطبین یافت نشد!") # Should not happen
            self.save_contacts()
            selection_window.destroy()
            # Refresh account book if the current tab is account book and any of the losers are selected
            if self.notebook.tab(self.notebook.select(), "text") == "دفتر حساب":
                self.show_contact_details() # General refresh, or more targeted if needed
            # Flag state already reset in blink_and_hide

        def cancel_action():
            # If cancel, flag should remain busy until clicked again or reset manually
            # For now, just destroy window. Flag state is already "normal" from blink_and_hide.
            selection_window.destroy()

        ttk.Button(btn_frame, text="تایید", command=confirm_action, style=STYLE_ACCENT_BUTTON).grid(row=0, column=0, padx=5, sticky="ew")
        ttk.Button(btn_frame, text="لغو", command=cancel_action, style=STYLE_MAIN_BUTTON).grid(row=0, column=1, padx=5, sticky="ew")
        selection_window.protocol("WM_DELETE_WINDOW", cancel_action)


    def create_account_book_tab(self):
        self.account_book_frame = ttk.Frame(self.notebook, style=STYLE_MAIN_FRAME)
        self.notebook.add(self.account_book_frame, text="دفتر حساب")

        # Main layout: List on right, Details on Left
        main_pane = ttk.PanedWindow(self.account_book_frame, orient=tk.HORIZONTAL)
        main_pane.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # --- Contact List Frame (Left Pane) ---
        contact_list_container = ttk.Frame(main_pane, style=STYLE_CONTENT_FRAME, width=250)
        main_pane.add(contact_list_container, weight=1) # Smaller weight for list
        contact_list_container.pack_propagate(False)


        header_frame = ttk.Frame(contact_list_container, style=STYLE_CONTENT_FRAME) # Match style
        header_frame.pack(fill=tk.X, pady=(0,5))

        ttk.Label(header_frame, text="مخاطبین", style=STYLE_HEADER_LABEL).pack(side=tk.LEFT, padx=(0,5))
        self.add_contact_button = ttk.Button(header_frame, text="افزودن", command=self.add_contact, style=STYLE_ACCENT_BUTTON, width=6) # Changed style for better visibility
        self.add_contact_button.pack(side=tk.RIGHT)

        # --- Search Bar ---
        search_frame = ttk.Frame(contact_list_container, style=STYLE_CONTENT_FRAME) # Match style
        search_frame.pack(fill=tk.X, pady=(5,5))
        
        ttk.Label(search_frame, text="جستجو:", style=STYLE_SUBHEADER_LABEL).pack(side=tk.LEFT, padx=(0,5))
        self.contact_search_var = tk.StringVar()
        self.contact_search_entry = ttk.Entry(search_frame, textvariable=self.contact_search_var, font=(FONT_FAMILY, FONT_SIZE_NORMAL))
        self.contact_search_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        self.contact_search_var.trace_add("write", self.filter_contacts)

        # --- Contact Treeview ---
        self.contact_treeview = ttk.Treeview(contact_list_container, columns=("name",), show="headings", selectmode="browse")
        self.contact_treeview.heading("name", text="نام مخاطب")
        self.contact_treeview.column("name", anchor="w")
        
        # Scrollbar for Treeview
        tree_scrollbar = ttk.Scrollbar(contact_list_container, orient="vertical", command=self.contact_treeview.yview)
        self.contact_treeview.configure(yscrollcommand=tree_scrollbar.set)
        
        tree_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.contact_treeview.pack(fill=tk.BOTH, expand=True)

        self.populate_contact_treeview() # Use a method to populate

        self.contact_treeview.bind("<<TreeviewSelect>>", self.show_contact_details)

        self.delete_button = ttk.Button(contact_list_container, text="حذف انتخاب شده", command=self.delete_selected_contact, style=STYLE_MAIN_BUTTON)
        self.delete_button.pack(side=tk.BOTTOM, fill=tk.X, pady=(5,0))


        # --- Contact Details Frame (Right Pane) ---
        self.contact_details_frame = ttk.Frame(main_pane, style=STYLE_CONTENT_FRAME)
        main_pane.add(self.contact_details_frame, weight=3) # Larger weight for details

        # Initial message in details frame
        ttk.Label(self.contact_details_frame, text="یک مخاطب را از لیست انتخاب کنید.", style=STYLE_SUBHEADER_LABEL, anchor="center").pack(fill=tk.BOTH, expand=True, padx=20, pady=20)

    def populate_contact_treeview(self, filter_text=None):
        for item in self.contact_treeview.get_children():
            self.contact_treeview.delete(item)
        
        contacts_to_display = sorted(self.contacts.keys())
        if filter_text:
            contacts_to_display = [name for name in contacts_to_display if filter_text.lower() in name.lower()]

        for name in contacts_to_display:
            self.contact_treeview.insert("", tk.END, text=name, values=(name,), iid=name)

    def filter_contacts(self, *args):
        search_term = self.contact_search_var.get()
        self.populate_contact_treeview(search_term)


    def delete_selected_contact(self):
        selected_item_id = self.contact_treeview.selection()
        if selected_item_id:
            name = self.contact_treeview.item(selected_item_id[0], "text")
            self.delete_contact(name, selected_item_id[0])


    def delete_contact(self, name, item_id_to_delete=None):
        confirm = tkinter.messagebox.askyesno("تایید حذف", f"آیا از حذف مخاطب '{name}' مطمئن هستید؟\n تمامی اطلاعات مالی او نیز حذف خواهد شد.", parent=self.master)
        if confirm:
            try:
                if item_id_to_delete:
                    if self.contact_treeview.exists(item_id_to_delete):
                         self.contact_treeview.delete(item_id_to_delete)
                else: # Fallback if item_id not provided (e.g. direct call)
                    for item_id in self.contact_treeview.get_children():
                        if self.contact_treeview.item(item_id, "text") == name:
                            if self.contact_treeview.exists(item_id):
                                self.contact_treeview.delete(item_id)
                            break
                
                for widget in self.contact_details_frame.winfo_children():
                    widget.destroy()
                ttk.Label(self.contact_details_frame, text="مخاطب حذف شد. یکی دیگر را انتخاب کنید.", style=STYLE_SUBHEADER_LABEL, anchor="center").pack(fill=tk.BOTH, expand=True, padx=20, pady=20)


                if name in self.contacts: del self.contacts[name]
                if name in self.credits: del self.credits[name]
                if name in self.credit_labels: del self.credit_labels[name] # Should be cleared by destroying frame

                self.save_contacts()
                self.save_credits()
            except Exception as e:
                print(f"خطا در حذف مخاطب: {e}")
                tkinter.messagebox.showerror("خطا", f"خطا در حذف مخاطب: {e}", parent=self.master)


    def show_contact_details(self, event=None):
        selected_item_id = self.contact_treeview.selection()
        for widget in self.contact_details_frame.winfo_children():
            widget.destroy()
        
        if selected_item_id:
            name = self.contact_treeview.item(selected_item_id[0], "text")
            if name in self.contacts:
                self.create_contact_details_layout(name, self.contact_details_frame)
            else:
                ttk.Label(self.contact_details_frame, text=f"اطلاعات مخاطب '{name}' یافت نشد.", style=STYLE_SUBHEADER_LABEL).pack(padx=20, pady=20)
        else:
             ttk.Label(self.contact_details_frame, text="یک مخاطب را از لیست انتخاب کنید.", style=STYLE_SUBHEADER_LABEL, anchor="center").pack(fill=tk.BOTH, expand=True, padx=20, pady=20)


    def create_contact_details_layout(self, name, parent_frame):
        parent_frame.configure(style=STYLE_CONTENT_FRAME) # Ensure parent is styled

        # Scrollable area for details if they overflow
        canvas = tk.Canvas(parent_frame, bg=self.style.lookup(STYLE_CONTENT_FRAME, 'background'), highlightthickness=0)
        scrollbar = ttk.Scrollbar(parent_frame, orient="vertical", command=canvas.yview)
        scrollable_frame = ttk.Frame(canvas, style=STYLE_CONTENT_FRAME)

        scrollable_frame.bind(
            "<Configure>",
            lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )
        canvas.create_window((0, 0), window=scrollable_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side="left", fill="both", expand=True)
        scrollbar.pack(side="right", fill="y")
        
        # --- Content of scrollable_frame ---
        content_pad_frame = ttk.Frame(scrollable_frame, style=STYLE_CONTENT_FRAME, padding=15)
        content_pad_frame.pack(fill=tk.BOTH, expand=True)

        # --- Header with Name and Edit Button ---
        header_details_frame = ttk.Frame(content_pad_frame, style=STYLE_CONTENT_FRAME)
        header_details_frame.pack(fill=tk.X, pady=(0, 15))

        self.current_contact_name_label = ttk.Label(header_details_frame, text=f"جزئیات حساب: {name}", style=STYLE_HEADER_LABEL)
        self.current_contact_name_label.pack(side=tk.LEFT, anchor="w")
        edit_name_button = ttk.Button(header_details_frame, text="ویرایش نام", style=STYLE_MAIN_BUTTON, command=lambda n=name: self.edit_contact_name_popup(n))
        edit_name_button.pack(side=tk.RIGHT, padx=(10,0))

        items = ["PC", "PS4", "بازی", "کیک", "نوشابه", "هایپ"] # PC/PS4 first

        # --- Items Section ---
        items_section_frame = ttk.Frame(content_pad_frame, style=STYLE_CONTENT_FRAME)
        items_section_frame.pack(fill=tk.X, pady=(0,10))

        for item_idx, item_name in enumerate(items):
            item_row_frame = ttk.Frame(items_section_frame, style=STYLE_CONTENT_FRAME)
            item_row_frame.pack(fill=tk.X, pady=3)

            label = ttk.Label(item_row_frame, text=item_name + ":", style=STYLE_SUBHEADER_LABEL, width=10, anchor="w")
            label.pack(side=tk.LEFT, padx=(0,10))

            if item_name in ["PC", "PS4"]:
                value_entry = ttk.Entry(item_row_frame, font=(FONT_FAMILY, FONT_SIZE_NORMAL), width=8, justify='center')
                value_entry.insert(0, str(self.contacts[name].get(item_name, 0)))
                value_entry.pack(side=tk.LEFT, padx=5)
                # Set background and foreground directly for better compatibility
                try:
                    value_entry.configure(background=COLOR_FRAME_BG, foreground=COLOR_TEXT, insertbackground=COLOR_TEXT)
                except tk.TclError:
                    pass
                value_entry.bind("<Return>", lambda e, i=item_name, entry=value_entry: self._update_pc_ps4_handler(name, i, entry, None)) # Total label updated by apply_payment or refresh
                value_entry.bind("<FocusOut>", lambda e, i=item_name, entry=value_entry: self._update_pc_ps4_handler(name, i, entry, None))
            else:
                value_label = ttk.Label(item_row_frame, text=str(self.contacts[name].get(item_name, 0)), width=5, style=STYLE_NORMAL_LABEL, anchor="center")
                value_label.pack(side=tk.LEFT, padx=10)
                minus_button = ttk.Button(item_row_frame, text="-", style=STYLE_ITEM_BUTTON,
                                          command=lambda i=item_name, vl=value_label: self._increment_decrement_item_handler(name, i, vl, None, -1))
                minus_button.pack(side=tk.LEFT, padx=(0,2))
                plus_button = ttk.Button(item_row_frame, text="+", style=STYLE_ITEM_BUTTON,
                                         command=lambda i=item_name, vl=value_label: self._increment_decrement_item_handler(name, i, vl, None, 1))
                plus_button.pack(side=tk.LEFT, padx=(2,5))
        
        ttk.Separator(content_pad_frame, orient='horizontal').pack(fill='x', pady=10)

        # --- Summary Section (Total & Credit) ---
        summary_frame = ttk.Frame(content_pad_frame, style=STYLE_CONTENT_FRAME)
        summary_frame.pack(fill=tk.X, pady=(5,10))
        summary_frame.columnconfigure(1, weight=1) # Make value labels expand

        ttk.Label(summary_frame, text="مجموع بدهی:", style=STYLE_HEADER_LABEL).grid(row=0, column=0, sticky="w", padx=(0,10))
        actual_total_label = ttk.Label(summary_frame, text="0", style=STYLE_TOTAL_LABEL, anchor='e')
        actual_total_label.grid(row=0, column=1, sticky="ew")

        ttk.Label(summary_frame, text="بستانکاری:", style=STYLE_HEADER_LABEL).grid(row=1, column=0, sticky="w", padx=(0,10), pady=(5,0))
        actual_credit_label = ttk.Label(summary_frame, text="0", style=STYLE_CREDIT_LABEL, anchor='e')
        actual_credit_label.grid(row=1, column=1, sticky="ew", pady=(5,0))
        self.credit_labels[name] = actual_credit_label # Store for direct update

        # --- Payment Section ---
        payment_section_frame = ttk.Frame(content_pad_frame, style=STYLE_CONTENT_FRAME)
        payment_section_frame.pack(fill=tk.X, pady=(10,0))
        
        ttk.Label(payment_section_frame, text="مبلغ پرداخت:", style=STYLE_SUBHEADER_LABEL).pack(side=tk.LEFT, padx=(0,10))
        self.payment_entry = ttk.Entry(payment_section_frame, font=(FONT_FAMILY, FONT_SIZE_NORMAL), width=12, justify='center')
        self.payment_entry.pack(side=tk.LEFT, padx=5)
        apply_payment_button = ttk.Button(payment_section_frame, text="اعمال پرداخت", style=STYLE_ACCENT_BUTTON,
                                        command=lambda: self.apply_payment(name, actual_total_label)) # Pass total label for update
        apply_payment_button.pack(side=tk.LEFT, padx=5)
        
        # Initial update
        self.update_total(name, actual_total_label)
        self.update_credit_label(name)

    def edit_contact_name_popup(self, old_name):
        edit_window = tk.Toplevel(self.master)
        edit_window.title("ویرایش نام مخاطب")
        edit_window.transient(self.master)
        edit_window.grab_set()
        self.center_toplevel_window(edit_window, width=380, height=180)

        container = ttk.Frame(edit_window, style=STYLE_CONTENT_FRAME, padding=20)
        container.pack(fill=tk.BOTH, expand=True)

        ttk.Label(container, text="نام جدید:", style=STYLE_SUBHEADER_LABEL).grid(row=0, column=0, padx=5, pady=5, sticky="w")
        name_entry = ttk.Entry(container, font=(FONT_FAMILY, FONT_SIZE_NORMAL), width=30)
        name_entry.insert(0, old_name)
        name_entry.grid(row=0, column=1, padx=5, pady=5, sticky="ew")
        name_entry.focus()
        name_entry.selection_range(0, tk.END)
        container.columnconfigure(1, weight=1)

        def save_edited_name(event=None):
            new_name = name_entry.get().strip()
            if not new_name:
                tkinter.messagebox.showwarning("هشدار", "نام مخاطب نمی‌تواند خالی باشد.", parent=edit_window)
                return
            
            if new_name == old_name: # No change
                edit_window.destroy()
                return

            if new_name in self.contacts:
                tkinter.messagebox.showerror("خطا", "این نام قبلاً در لیست مخاطبین وجود دارد.", parent=edit_window)
                return

            # Update contacts
            self.contacts[new_name] = self.contacts.pop(old_name)
            
            # Update credits if exists
            if old_name in self.credits:
                self.credits[new_name] = self.credits.pop(old_name)
            
            # Update credit_labels dictionary key if exists
            if old_name in self.credit_labels:
                self.credit_labels[new_name] = self.credit_labels.pop(old_name)

            self.save_contacts()
            self.save_credits()

            self.populate_contact_treeview(self.contact_search_var.get()) # Repopulate tree
            self.contact_treeview.selection_set(new_name) # Select the renamed contact
            self.contact_treeview.focus(new_name)
            
            edit_window.destroy()
            self.show_contact_details() # Refresh details view with new name

        btn_frame = ttk.Frame(container, style=STYLE_CONTENT_FRAME)
        btn_frame.grid(row=1, column=0, columnspan=2, pady=(15,0))
        ttk.Button(btn_frame, text="ذخیره", command=save_edited_name, style=STYLE_ACCENT_BUTTON).pack(side=tk.LEFT, padx=5)
        ttk.Button(btn_frame, text="لغو", command=edit_window.destroy, style=STYLE_MAIN_BUTTON).pack(side=tk.LEFT, padx=5)
        name_entry.bind("<Return>", save_edited_name)
        edit_window.protocol("WM_DELETE_WINDOW", edit_window.destroy)

    def _update_pc_ps4_handler(self, name, item, entry_widget, total_label_widget_optional):
        try:
            new_value = int(entry_widget.get())
            if new_value >= 0:
                self.contacts[name][item] = new_value
                if total_label_widget_optional: # If a total label is passed directly for update
                    self.update_total(name, total_label_widget_optional)
                else: # Otherwise, trigger a full refresh of details if visible
                    self.show_contact_details() # This will re-calc and re-draw
                self.save_contacts()
                self.master.focus_set() # Remove focus from entry
            else:
                tkinter.messagebox.showerror("خطا", "مقدار نمی‌تواند منفی باشد.", parent=self.master)
                entry_widget.delete(0, tk.END)
                entry_widget.insert(0, str(self.contacts[name].get(item, 0)))
        except ValueError:
            tkinter.messagebox.showerror("خطا", "لطفاً عدد صحیح وارد کنید!", parent=self.master)
            entry_widget.delete(0, tk.END)
            entry_widget.insert(0, str(self.contacts[name].get(item, 0)))

    def _increment_decrement_item_handler(self, name, item, value_label_widget, total_label_widget_optional, delta):
        current_value = self.contacts[name].get(item, 0)
        new_val = current_value + delta
        if new_val >= 0:
            self.contacts[name][item] = new_val
            value_label_widget.config(text=str(new_val))
            if total_label_widget_optional:
                self.update_total(name, total_label_widget_optional)
            else:
                self.show_contact_details() # Refresh
            self.save_contacts()


    def apply_payment(self, name, total_label_widget): # total_label_widget is the ttk.Label for total
        try:
            payment_str = self.payment_entry.get()
            payment = 0
            if payment_str.strip(): # If not empty
                payment = int(payment_str)

            if payment < 0:
                tkinter.messagebox.showwarning("هشدار", "مبلغ پرداخت نمی‌تواند منفی باشد!", parent=self.master)
                return
            
            current_credit = self.credits.get(name, 0)
            total_amount_available = payment + current_credit

            # Reset credit as it's being used now
            self.credits[name] = 0

            # Define item types and their corresponding prices in priority order
            # PC/PS4 are often highest priority as they are time-based and accrue continuously
            items_priority = ["PC", "PS4", "بازی", "کیک", "نوشابه", "هایپ"]

            # Apply available amount to clear full units of debts in priority order
            for item_name in items_priority:
                if total_amount_available <= 0:
                    break # No more amount to apply

                price_per_unit = self.prices.get(item_name, 0)
                if price_per_unit <= 0:
                    continue # Cannot pay off items with zero price

                current_units = self.contacts[name].get(item_name, 0)
                if current_units <= 0:
                    continue # No debt for this item

                # Calculate how many full units of this item can be paid for
                # Use integer division as we can only pay for full units with this logic
                units_can_afford = total_amount_available // price_per_unit

                # Calculate how many units to actually pay for (limited by debt and affordability)
                units_to_pay = min(current_units, units_can_afford)

                if units_to_pay > 0:
                    # Reduce item units
                    self.contacts[name][item_name] -= units_to_pay

                    # Reduce the total amount available
                    cost_covered = units_to_pay * price_per_unit
                    total_amount_available -= cost_covered

            # Any remaining amount becomes new credit
            if total_amount_available > 0:
                self.credits[name] = total_amount_available
            # If total_amount_available is 0 or less, credit remains 0.

            self.save_contacts()
            self.save_credits()

            # Refresh the display
            self.show_contact_details() # This will call update_total and update_credit_label
            self.payment_entry.delete(0, tk.END)

        except ValueError:
            tkinter.messagebox.showerror("خطا", "لطفاً مبلغ پرداخت را به صورت عدد صحیح وارد کنید.", parent=self.master)
        except Exception as e:
            print(f"خطای ناشناخته در اعمال پرداخت: {e}")
            tkinter.messagebox.showerror("خطای ناشناخته", f"خطایی در اعمال پرداخت رخ داد: {e}", parent=self.master)


    def deduct_from_credit(self, name): # As per original logic if credit is high
        credit = self.credits.get(name, 0)
        # Order of items to "buy back" with credit
        items_to_buy = ["بازی", "کیک", "نوشابه", "هایپ"] # PC/PS4 usually not bought back this way
        
        for item in items_to_buy:
            price = self.prices.get(item, float('inf')) # Avoid division by zero if price missing
            if price == 0 : continue

            # Example: Limit to reducing debt, not adding new items beyond 0 debt for that item
            # Or, if it's about converting pure credit to items, the logic might differ.
            # Assuming this is about reducing existing item counts if credit is available.
            # The original logic was `self.contacts[name][item] -= 1` which implies reducing debt.
            # And `self.contacts[name][item] < 10` was a limit.

            # Let's assume it means if you have credit, and you owe for "بازی", it reduces "بازی" count.
            # This seems more like `apply_payment`'s job.
            # If `deduct_from_credit` is about converting pure credit (e.g., overpayment) into items:
            # while credit >= price and self.contacts[name].get(item, 0) < 10: # Max 10 of each "free" item
            #    credit -= price
            #    self.contacts[name][item] = self.contacts[name].get(item, 0) + 1
            
            # Sticking to the original intent which seemed to be reducing debt if credit was available,
            # but `apply_payment` already handles this better.
            # For now, this function might be redundant or needs clarification on its exact purpose.
            # If it's about converting pure credit (e.g., overpayment) into items:
            while credit >= self.prices.get(item, float('inf')) and self.contacts[name].get(item,0) < 10 : # Example limit
                 # This logic is if credit is used to *add* items (e.g. free items for credit)
                 # self.contacts[name][item] = self.contacts[name].get(item, 0) + 1
                 # credit -= self.prices[item]
                 # This part needs clear definition. For now, I'll keep it minimal based on original.
                 # The original `self.contacts[name][item] -= 1` in `deduct_from_credit` is likely a bug
                 # if it's meant to *give* items for credit.
                 # If it's to *pay off* debt using credit, `apply_payment` is the place.
                 pass # Placeholder - review this function's purpose

        self.credits[name] = credit
        self.update_credit_label(name)
        self.save_credits()
        self.save_contacts()


    def update_credit_label(self, name):
        credit_amount = self.credits.get(name, 0)
        formatted_credit = f"{credit_amount:,.0f}" # No decimals for credit
        if name in self.credit_labels and self.credit_labels[name].winfo_exists():
            self.credit_labels[name].config(text=formatted_credit)

    def save_credits(self):
        with open("credits.json", "w", encoding='utf-8') as f: # Added encoding
            json.dump(self.credits, f, ensure_ascii=False, indent=4)

    def load_credits(self):
        try:
            with open("credits.json", "r", encoding='utf-8') as f: # Added encoding
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return {}


    def calculate_total(self, name):
        total = 0
        contact_data = self.contacts.get(name, {})
        for item, count in contact_data.items():
            total += count * self.prices.get(item, 0) # Use .get for price too
        return total


    def add_contact(self):
        new_contact_window = tk.Toplevel(self.master)
        new_contact_window.title("افزودن مخاطب جدید")
        new_contact_window.transient(self.master)
        new_contact_window.grab_set()
        self.center_toplevel_window(new_contact_window, width=350, height=180)

        container = ttk.Frame(new_contact_window, style=STYLE_CONTENT_FRAME, padding=20)
        container.pack(fill=tk.BOTH, expand=True)

        ttk.Label(container, text="نام مخاطب:", style=STYLE_SUBHEADER_LABEL).grid(row=0, column=0, padx=5, pady=5, sticky="w")
        name_entry = ttk.Entry(container, font=(FONT_FAMILY, FONT_SIZE_NORMAL), width=30)
        name_entry.grid(row=0, column=1, padx=5, pady=5, sticky="ew")
        name_entry.focus()
        container.columnconfigure(1, weight=1)

        def save_new_contact(event=None):
            name = name_entry.get().strip()
            if name:
                if name in self.contacts:
                    tkinter.messagebox.showerror("خطا", "این نام قبلاً در لیست مخاطبین وجود دارد.", parent=new_contact_window)
                else:
                    self.contacts[name] = {"بازی": 0, "کیک": 0, "نوشابه": 0, "هایپ": 0, "PC": 0, "PS4": 0}
                    self.save_contacts()
                    self.populate_contact_treeview(self.contact_search_var.get()) # Repopulate with current filter
                    # Try to select the newly added contact
                    self.contact_treeview.selection_set(name) # Select the new contact
                    self.contact_treeview.focus(name) # Focus it
                    new_contact_window.destroy()
                    self.show_contact_details() # Show details of new contact
            else:
                tkinter.messagebox.showwarning("هشدار", "نام مخاطب نمی‌تواند خالی باشد.", parent=new_contact_window)

        btn_frame = ttk.Frame(container, style=STYLE_CONTENT_FRAME) # Match style
        btn_frame.grid(row=1, column=0, columnspan=2, pady=(15,0))
        
        save_button = ttk.Button(btn_frame, text="ذخیره", command=save_new_contact, style=STYLE_ACCENT_BUTTON)
        save_button.pack(side=tk.LEFT, padx=5)
        cancel_button = ttk.Button(btn_frame, text="لغو", command=new_contact_window.destroy, style=STYLE_MAIN_BUTTON)
        cancel_button.pack(side=tk.LEFT, padx=5)
        
        name_entry.bind("<Return>", save_new_contact)
        new_contact_window.protocol("WM_DELETE_WINDOW", new_contact_window.destroy)


    def update_total(self, name, total_label_widget): # total_label_widget is the ttk.Label
        total = self.calculate_total(name)
        formatted_total = f"{total:,.0f}" # No decimals
        if total_label_widget.winfo_exists():
            total_label_widget.config(text=formatted_total)
        # self.save_contacts() # Saving is done by handlers or apply_payment


    def has_active_timers(self):
        if any(timer.get("running", False) for timer in self.device_timers.values()):
            return True
        # if self.ps4_timer_running: # Removed, ps4 timers are in device_timers
        #     return True
        if hasattr(self, 'flag_states') and any(flag.get("status") == "busy" for flag in self.flag_states.values()):
            return True
        return False


    def on_close(self):
        if self.has_active_timers():
            if not tkinter.messagebox.askyesno(
                "تایمرهای فعال",
                "هنوز تایمرهای فعالی در برنامه وجود دارد.\n"
                "آیا مطمئن هستید که می‌خواهید خارج شوید؟ (اطلاعات تایمرهای فعال ذخیره نخواهد شد)",
                parent=self.master):
                return

        confirm_close = tkinter.messagebox.askyesno(
            "تأیید خروج",
            "آیا می‌خواهید از برنامه خارج شوید؟",
            parent=self.master
        )
        if confirm_close:
            self.save_contacts()
            self.save_credits()
            self.save_device_assignments()
            self.save_prices() # Save prices on close too
            self.master.destroy()


    def open_settings(self):
        settings_window = tk.Toplevel(self.master)
        settings_window.title("تنظیمات قیمت")
        settings_window.transient(self.master)
        settings_window.grab_set()
        # Dynamic height based on items
        num_items = len(self.prices)
        win_height = 100 + num_items * 40 # Base height + per item height
        self.center_toplevel_window(settings_window, width=400, height=win_height)

        container = ttk.Frame(settings_window, style=STYLE_CONTENT_FRAME, padding=20)
        container.pack(fill=tk.BOTH, expand=True)

        entries = {}
        # Ensure all expected items are in prices for settings
        default_items_for_settings = ["بازی", "کیک", "نوشابه", "هایپ", "PC", "PS4"]
        for item_name in default_items_for_settings:
            if item_name not in self.prices: # Ensure default price if missing
                 self.prices[item_name] = self.load_prices().get(item_name, 0)


        for i, (item, price) in enumerate(self.prices.items()):
            if item not in default_items_for_settings: continue # Only show expected items

            ttk.Label(container, text=item + ":", style=STYLE_SUBHEADER_LABEL).grid(row=i, column=0, padx=5, pady=5, sticky="w")
            entry = ttk.Entry(container, font=(FONT_FAMILY, FONT_SIZE_NORMAL), width=15, justify="right")
            entry.insert(0, str(price))
            entry.grid(row=i, column=1, padx=5, pady=5, sticky="ew")
            entries[item] = entry
        container.columnconfigure(1, weight=1)

        def save_settings_action():
            try:
                for item_key, entry_widget in entries.items():
                    self.prices[item_key] = int(entry_widget.get())
                self.save_prices()
                settings_window.destroy()
            except ValueError:
                tkinter.messagebox.showerror("خطا", "لطفاً برای تمامی قیمت‌ها مقادیر عددی صحیح وارد کنید.", parent=settings_window)

        save_button = ttk.Button(container, text="ذخیره تنظیمات", command=save_settings_action, style=STYLE_ACCENT_BUTTON)
        save_button.grid(row=len(self.prices) +1 , column=0, columnspan=2, pady=(20,0))
        settings_window.protocol("WM_DELETE_WINDOW", settings_window.destroy)


if __name__ == "__main__":
    if not check_and_acquire_lock():
        # Create a simple root window just for the messagebox if lock fails early
        temp_root = tk.Tk()
        temp_root.withdraw() # Hide the root window
        tkinter.messagebox.showinfo("برنامه در حال اجرا", "یک نمونه از برنامه گیم نت از قبل باز است.", parent=None)
        temp_root.destroy()
        sys.exit(0)

    root = tk.Tk()
    app = GameNetApp(root)
    root.mainloop()
