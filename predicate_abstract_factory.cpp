#include "predicate_abstract_factory.hpp"
class is_equal : public predicate
{
	public:
		virtual bool operator()(const state& s) const override 
		{
			return bf::is_regular_file(s.file) && bf::file_size(s.file)==get_inner_state().size;
		}
		virtual predicate* clone() const override 
		{
			return new is_equal(get_inner_state());
		}
		is_equal(const inner_state& st) : predicate(st){}
		is_equal(){}
};

class is_more : public predicate
{
	public:
		virtual bool operator()(const state& s) const override
		{
			return bf::is_regular_file(s.file) && bf::file_size(s.file)>get_inner_state().size;
		}
		virtual predicate* clone() const override
		{
			return new is_more(get_inner_state());
		}
		is_more(const inner_state& st) : predicate(st){}
		is_more(){}
};

class is_less : public predicate
{
	public:
		virtual bool operator()(const state& s) const override
		{
			return bf::is_regular_file(s.file) && bf::file_size(s.file)<get_inner_state().size;
		}
		virtual predicate* clone() const override
		{
			return new is_less(get_inner_state());
		}
		is_less(const inner_state& st) : predicate(st){}
		is_less(){}
};

class contains : public predicate
{
	public:
		virtual bool operator()(const state& s) const override
		{
			auto fn=s.file.filename().string();
			return bf::is_regular_file(s.file) && 
				fn.find(get_inner_state().str)!=std::string::npos;
		}
		virtual predicate* clone() const override
		{
			return new contains(get_inner_state());
		}
		contains(const inner_state& st) : predicate(st){}
		contains(){}
};

class is_name_equals : public predicate
{
	public:
		virtual bool operator()(const state& s) const override
		{
			return bf::is_regular_file(s.file) && 
				s.file.filename().string()==get_inner_state().str;
		}
		virtual predicate* clone() const override
		{
			return new is_name_equals(get_inner_state());
		}
		is_name_equals(const inner_state& st) : predicate(st){}
		is_name_equals(){}
};

static bool is_hidden(const bf::path &p)
{
    auto name = p.filename().string();
	if (name != ".." &&
		name != "."  &&
		name[0] == '.')
	{
	    return true;
	}
	return false;
}

class attribute_is : public predicate
{
	public:
		virtual bool operator()(const state& s) const override
		{
			switch(get_inner_state().attr)
			{
				case attribute::file:
				{
					return bf::is_regular_file(s.file);
				}
				case attribute::directory:
				{
					return bf::is_directory(s.file);
				}
				case attribute::hidden:
				{
					return is_hidden(s.file);
				}
				case attribute::readonly:
				{
					return bf::status(s.file).permissions()==(bf::owner_read | bf::group_read | bf::others_read);
				}
				default:
					return false;
			}
		}
		virtual predicate* clone() const override
		{
			return new attribute_is(get_inner_state());
		}
		attribute_is(const inner_state& st) : predicate(st){}
		attribute_is(){}
};

class attribute_not : public predicate
{
	public:
		virtual bool operator()(const state& s) const override
		{
			switch(get_inner_state().attr)
			{
				case attribute::file:
				{
					return !bf::is_regular_file(s.file);
				}
				case attribute::directory:
				{
					return !bf::is_directory(s.file);
				}
				case attribute::hidden:
				{
					return !is_hidden(s.file);
				}
				case attribute::readonly:
				{
					return !bf::status(s.file).permissions()==(bf::owner_read | bf::group_read | bf::others_read);
				}
				default:
					return false;
			}
		}
		virtual predicate* clone() const override
		{
			return new attribute_not(get_inner_state());
		}
		attribute_not(const inner_state& st) : predicate(st){}
		attribute_not(){}
};

void initialize_factory(predicate_abstract_factory& fact)
{
	// Size
	fact.register_function("is_equal", new is_equal);	
	fact.register_function("is_more", new is_more);	
	fact.register_function("is_less", new is_less);	

	// Name
	fact.register_function("contains", new contains);	
	fact.register_function("is_name_equals", new is_name_equals);	

	// Attribute
	fact.register_function("attribute_is", new attribute_is);	
	fact.register_function("attribute_not", new attribute_not);	
}

#include <iostream>
#include <regex>

inline static std::string extract_path(const std::string& str)
{
	std::string path=str.substr(1, str.length()-2);
	path = std::regex_replace(path, std::regex("^ +| +$|/+$"), "$1");
    if(path[path.length()-1] != '/')
    {
	    path+="/";
    }
	return path;
}

void predicate_driver(const std::string& str, const predicate* pred)
{
	state s;
	std::string path=extract_path(str);
	bf::recursive_directory_iterator dir{bf::path(path)}, end;
	auto it=bf::begin(dir);
	while(it!=end)
	{
		s.file=*it;
		if((*pred)(s))
		{
			auto fn=it->path().string();
			std::cout<<"\t"<<fn.substr(path.length(), fn.length()-path.length())<<std::endl;
		}
		try
		{
			it++;
		}
		catch(const bf::filesystem_error& err)
		{
			std::cout<<err.what()<<std::endl;
			continue;
		}
	}
	delete pred;
}
