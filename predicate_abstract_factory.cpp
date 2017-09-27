#include "predicate_abstract_factory.hpp"

class is_equal : public predicate
{
	public:
		virtual bool operator()(const state& s) const override 
		{
			return bf::file_size(s.file)==get_inner_state().size;
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
			return bf::file_size(s.file)>get_inner_state().size;
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
			return bf::file_size(s.file)<get_inner_state().size;
		}
		virtual predicate* clone() const override
		{
			return new is_less(get_inner_state());
		}
		is_less(const inner_state& st) : predicate(st){}
		is_less(){}
};

void initialize_factory(predicate_abstract_factory& fact)
{
	fact.register_function("is_equal", new is_equal);	
	fact.register_function("is_more", new is_more);	
	fact.register_function("is_less", new is_less);	
}
